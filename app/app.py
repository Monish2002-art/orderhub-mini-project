import os
from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/")
def index():
    return "OrderHub API"

@app.route("/health")
def health():
    return jsonify({"status": "UP"})

@app.route("/orders")
def orders():
    return jsonify([
        {"id": 1, "item": "Widget A", "qty": 5},
        {"id": 2, "item": "Widget B", "qty": 2}
    ])

@app.route("/version")
def version():
    return jsonify({
        "version": os.getenv("APP_VERSION", "1.0.0"),
        "build": os.getenv("BUILD_NUMBER", "unknown"),
        "commit": os.getenv("GIT_COMMIT", "unknown")
    })

if __name__ == "__main__":
    app.use_reloader = False
    app.run(host="0.0.0.0", port=8080)