from flask import Flask, request, render_template, redirect, url_for
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

@app.route('/')
def index():
    comments = Comment.query.all()
    return render_template('index.html', comments=comments)

@app.route('/add_comment', methods=['POST'])
def add_comment():
    text = request.form['text']
    new_comment = Comment(text=text)
    db.session.add(new_comment)
    db.session.commit()
    return redirect(url_for('index'))

if __name__ == '__main__':
    db.create_all()
    app.run(host='0.0.0.0', port=5000)