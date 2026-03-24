from flask import Flask, render_template, request


app = Flask(__name__)

@app.route("/")
def main():
    model = {"title": "Hello DevOps Fans."}
    return render_template('index.html', model=model)

# @app.route("/")
# def main():
#     model = {"title":  "Hello Build Trigger."}
#     return render_template("index.html", model=model)
 
if __name__ == "__main__":
    # app.run(host='0.0.0.0', port=8080, debug=True, threaded=True)
    port = int(os.environ.get("PORT", 8080))  # fallback to 8080 locally
    app.run(host='0.0.0.0', port=port, debug=True, threaded=True)
