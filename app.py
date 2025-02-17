from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://postgres:password@postgres/postgres'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

class Comment(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    text = db.Column(db.String(200), nullable=False)

    def __repr__(self):
        return f'<Comment {self.id} - {self.text}>'

@app.route('/comments', methods=['GET'])
def get_comments():
    comments = Comment.query.all()
    return jsonify([{'id': c.id, 'text': c.text} for c in comments])

@app.route('/comments', methods=['POST'])
def add_comment():
    data = request.get_json()
    new_comment = Comment(text=data['text'])
    db.session.add(new_comment)
    db.session.commit()
    return jsonify({'id': new_comment.id, 'text': new_comment.text}), 201

if __name__ == '__main__':
    db.create_all()
    app.run(host='0.0.0.0', port=5000)