from datetime import datetime
from flask import Flask, request, flash, url_for, redirect, render_template, abort
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)
 
app.config.from_pyfile('professionConfig.cfg')
db = SQLAlchemy(app)
app.debug = True
 
class Profession(db.Model):
    __tablename__ = 'profession'
    id = db.Column('id', db.Integer, primary_key=True)
    fname = db.Column(db.String(60))
    lname = db.Column(db.String(60))
    email = db.Column(db.String(60))
    profession = db.Column(db.String(60))
    create_date = db.Column(db.DateTime)
 
    def __init__(self, fname, lname, email, profession):
        self.fname = fname
        self.lname = lname
        self.email = email
        self.profession = profession
        self.create_date = datetime.utcnow()
 
@app.route('/')

#@app.route('/hello')
def index():
    return render_template('index.html',
        profession=Profession.query.order_by(Profession.create_date.desc()).all()
    )
 
@app.route('/new', methods=['GET', 'POST'])
def new():
    if request.method == 'POST':
            profession = Profession(request.form['fname'], request.form['lname'], request.form['email'], request.form['profession'])
            db.session.add(profession)
            db.session.commit()
            return redirect(url_for('index'))
    return render_template('new.html')

if __name__ == '__main__':
    app.run(host='0.0.0.0')
