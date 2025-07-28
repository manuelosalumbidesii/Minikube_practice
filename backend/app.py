from flask import Flask, request, jsonify
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)
notes = []

# Prometheus metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP Requests', ['method', 'endpoint'])
NOTES_ADDED = Counter('notes_added_total', 'Total notes added')
NOTES_DELETED = Counter('notes_deleted_total', 'Total notes deleted')

@app.before_request
def before_request():
    REQUEST_COUNT.labels(method=request.method, endpoint=request.path).inc()

@app.route("/notes", methods=["GET"])
def get_notes():
    return jsonify(notes)


@app.route("/notes", methods=["POST"])
def add_note():
    note = request.json.get("note")
    if note:
        notes.append(note)
        NOTES_ADDED.inc()
    return jsonify({"message": "Note added"}), 201


@app.route("/notes/<int:index>", methods=["DELETE"])
def delete_note(index):
    try:
        notes.pop(index)
        NOTES_DELETED.inc()
        return jsonify({"message": "Note deleted"}), 200
    except IndexError:
        return jsonify({"error": "Invalid index"}), 400

# Prometheus /metrics endpoint
@app.route("/metrics")
def metrics():
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
