from flask import Flask, request, render_template
import requests

app = Flask(__name__)

# Change this URL if your backend service name or port changes in Kubernetes
BACKEND_URL = "http://backend-service:5000"

@app.route("/", methods=["GET", "POST"])
def index():
    notes = []
    
    if request.method == "POST":
        note = request.form.get("note")
        if note:
            # Send the note to backend API
            try:
                requests.post(f"{BACKEND_URL}/notes", json={"note": note})
            except Exception as e:
                print("Error posting note:", e)

    # Get the updated notes list from backend API
    try:
        response = requests.get(f"{BACKEND_URL}/notes")
        if response.ok:
            notes = response.json()
    except Exception as e:
        print("Error fetching notes:", e)
    
    return render_template("index.html", notes=notes)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
