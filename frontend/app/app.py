from flask import Flask, request, render_template

app = Flask(__name__)

@app.route("/", methods=["GET", "POST"])
def index():
    notes = []
    if request.method == "POST":
        note = request.form.get("note")
        if note:
            notes.append(note)
    return render_template("index.html", notes=notes)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
