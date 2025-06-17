from click import prompt
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_bcrypt import Bcrypt
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity
from flask_cors import CORS
from datetime import datetime, timedelta
from transformers import pipeline

app = Flask(__name__)
# Enable CORS so Flutter can call from another host/emulator
CORS(app)

# Configuration
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///financial_buddy.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['JWT_SECRET_KEY'] = 'replace_with_a_strong_secret_key'

db = SQLAlchemy(app)
bcrypt = Bcrypt(app)
jwt = JWTManager(app)

insights_generator = pipeline("text-generation", model="distilgpt2")

# Models
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    phone = db.Column(db.String(20), nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)
    registered_on = db.Column(db.DateTime, default=datetime.utcnow)
    transactions = db.relationship('Transaction', backref='user', lazy=True)
    budgets = db.relationship('BudgetCategory', backref='user', lazy=True)
    goals = db.relationship('Goal', backref='user', lazy=True)

    def check_password(self, password):
        return bcrypt.check_password_hash(self.password_hash, password)

class Transaction(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    type = db.Column(db.String(10), nullable=False)  # 'income' or 'expense'
    category = db.Column(db.String(50), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    date = db.Column(db.DateTime, default=datetime.utcnow)
    notes = db.Column(db.String(255))

class BudgetCategory(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    category = db.Column(db.String(50), nullable=False)
    budget = db.Column(db.Float, nullable=False)

class Goal(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    title = db.Column(db.String(120), nullable=False)
    target = db.Column(db.Float, nullable=False)
    saved = db.Column(db.Float, nullable=False)
    date = db.Column(db.String(20), nullable=False)

# Routes
@app.route('/signup', methods=['POST'])
def signup():
    data = request.get_json()
    name = data.get('name')
    email = data.get('email')
    phone = data.get('phone')
    password = data.get('password')

    if User.query.filter_by(email=email).first():
        return jsonify({'msg': 'User already exists'}), 409

    pw_hash = bcrypt.generate_password_hash(password).decode('utf-8')
    user = User(name=name, email=email, phone=phone, password_hash=pw_hash)
    db.session.add(user)
    db.session.commit()

    access_token = create_access_token(identity=str(user.id))
    return jsonify({'access_token': access_token}), 201

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    user = User.query.filter_by(email=email).first()
    if not user or not user.check_password(password):
        return jsonify({'msg': 'Invalid credentials'}), 401

    access_token = create_access_token(identity=str(user.id))
    return jsonify({'access_token': access_token}), 200

@app.route('/profile', methods=['GET'])
@jwt_required()
def profile():
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    return jsonify({'name': user.name, 'email': user.email, 'phone': user.phone}), 200

@app.route('/transaction', methods=['POST'])
@jwt_required()
def add_transaction():
    user_id = get_jwt_identity()
    data = request.get_json()
    date_parsed = datetime.fromisoformat(data.get('date')) if data.get('date') else datetime.utcnow()

    tx = Transaction(
        user_id=user_id,
        type=data['type'],
        category=data['category'],
        amount=data['amount'],
        date=date_parsed,
        notes=data.get('notes', '')
    )
    db.session.add(tx)
    db.session.commit()
    return jsonify({'msg': 'Transaction added', 'id': tx.id}), 201

@app.route('/transactions', methods=['GET'])
@jwt_required()
def list_transactions():
    user_id = get_jwt_identity()
    txs = Transaction.query.filter_by(user_id=user_id).order_by(Transaction.date.desc()).all()
    return jsonify([{
        'id': t.id,
        'type': t.type,
        'category': t.category,
        'amount': t.amount,
        'date': t.date.isoformat(),
        'notes': t.notes
    } for t in txs]), 200

@app.route('/summary', methods=['GET'])
@jwt_required()
def monthly_summary():
    user_id = get_jwt_identity()
    now = datetime.utcnow()
    month_start = datetime(now.year, now.month, 1)

    txs = Transaction.query.filter(
        Transaction.user_id == user_id,
        Transaction.date >= month_start
    ).all()

    income = sum(t.amount for t in txs if t.type == 'income')
    expenses = sum(t.amount for t in txs if t.type == 'expense')
    savings = income - expenses

    return jsonify({'income': income, 'expenses': expenses, 'savings': savings}), 200

# ----- BUDGETS -----
@app.route('/budgets', methods=['GET'])
@jwt_required()
def get_budgets():
    user_id = get_jwt_identity()
    now = datetime.utcnow()
    month_start = datetime(now.year, now.month, 1)

    # Calculate spent per category
    txs = Transaction.query.filter(
        Transaction.user_id == user_id,
        Transaction.date >= month_start,
        Transaction.type == 'expense'
    ).all()

    spent_map = {}
    for t in txs:
        spent_map[t.category] = spent_map.get(t.category, 0.0) + t.amount

    cats = BudgetCategory.query.filter_by(user_id=user_id).all()
    result = []
    for b in cats:
        result.append({
            'category': b.category,
            'budget': b.budget,
            'spent': spent_map.get(b.category, 0.0)
        })
    return jsonify(result), 200

@app.route('/budgets', methods=['POST'])
@jwt_required()
def add_budget():
    user_id = get_jwt_identity()
    data = request.get_json()

    cat = data.get('category')
    amt = data.get('budget')

    bc = BudgetCategory.query.filter_by(user_id=user_id, category=cat).first()
    if bc:
        bc.budget = amt
    else:
        bc = BudgetCategory(user_id=user_id, category=cat, budget=amt)
        db.session.add(bc)

    db.session.commit()
    return jsonify({'msg': 'Budget saved'}), 201

# ----- GOALS -----
# ----- GOALS -----
@app.route('/goals', methods=['GET', 'POST', 'PUT'])
@jwt_required()
def handle_goals():
    user_id = get_jwt_identity()

    if request.method == 'GET':
        goals = Goal.query.filter_by(user_id=user_id).all()
        return jsonify([{
            'title': g.title,
            'target': g.target,
            'saved': g.saved,
            'date': g.date
        } for g in goals]), 200

    elif request.method == 'POST':
        data = request.get_json()
        g = Goal(
            user_id=user_id,
            title=data['title'],
            target=data['target'],
            saved=data['saved'],
            date=data['date']
        )
        db.session.add(g)
        db.session.commit()
        return jsonify({'msg': 'Goal added'}), 201

    elif request.method == 'PUT':
        data = request.get_json()
        title = data.get('title')

        goal = Goal.query.filter_by(user_id=user_id, title=title).first()
        if not goal:
            return jsonify({'msg': 'Goal not found'}), 404

        # Update fields
        goal.target = data.get('target', goal.target)
        goal.saved = data.get('saved', goal.saved)
        goal.date = data.get('date', goal.date)

        db.session.commit()
        return jsonify({'msg': 'Goal updated'}), 200


#---AI INSIGHTS ----#

@app.route('/insights', methods=['GET'])
@jwt_required()
def ai_insights():
    from collections import Counter
    user_id = get_jwt_identity()
    now = datetime.utcnow()

    # Calculate start of this and last month
    this_month_start = datetime(now.year, now.month, 1)
    last_month = this_month_start.replace(day=1) - timedelta(days=1)
    last_month_start = datetime(last_month.year, last_month.month, 1)

    # Fetch transactions
    txs_this = Transaction.query.filter(
        Transaction.user_id == user_id,
        Transaction.date >= this_month_start
    ).all()

    txs_last = Transaction.query.filter(
        Transaction.user_id == user_id,
        Transaction.date >= last_month_start,
        Transaction.date < this_month_start
    ).all()

    # Current month
    income_this = sum(t.amount for t in txs_this if t.type == 'income')
    expense_this = sum(t.amount for t in txs_this if t.type == 'expense')
    cats_this = Counter(t.category for t in txs_this if t.type == 'expense')
    top_this = [c for c, _ in cats_this.most_common(3)]

    # Last month
    income_last = sum(t.amount for t in txs_last if t.type == 'income')
    expense_last = sum(t.amount for t in txs_last if t.type == 'expense')
    cats_last = Counter(t.category for t in txs_last if t.type == 'expense')
    top_last = [c for c, _ in cats_last.most_common(3)]

    # Change calculations
    income_diff = income_this - income_last
    expense_diff = expense_this - expense_last

    prompt = (
        f"Last month: Income ₹{income_last:.2f}, Expenses ₹{expense_last:.2f}. "
        f"This month: Income ₹{income_this:.2f}, Expenses ₹{expense_this:.2f}. "
        f"Top spending last month: {', '.join(top_last)}. "
        f"Top spending this month: {', '.join(top_this)}. "
        "Give a one-line financial insight based on this trend."
    )

    out = insights_generator(prompt, max_new_tokens=30,do_sample=True, temperature=0.7, truncation=True)
    tip = out[0]['generated_text'][len(prompt):].strip()
    return jsonify({'insight': tip}), 200


if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(host='0.0.0.0', port=5000, debug=True)