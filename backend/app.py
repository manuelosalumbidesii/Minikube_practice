from flask import Flask, request, jsonify


app = Flask(__name__)
notes = []


@app.route("/notes", methods=["GET"])
def get_notes():
    return jsonify(notes)


@app.route("/notes", methods=["POST"])
def add_note():
    note = request.json.get("note")
    if note:
        notes.append(note)
    return jsonify({"message": "Note added"}), 201


@app.route("/notes/<int:index>", methods=["DELETE"])
def delete_note(index):
    try:
        notes.pop(index)
        return jsonify({"message": "Note deleted"}), 200
    except IndexError:
        return jsonify({"error": "Invalid index"}), 400


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
