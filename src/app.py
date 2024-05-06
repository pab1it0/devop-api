import os
from flask import Flask

app = Flask(__name__)

port = int(os.getenv('PORT', 5000))
host = os.getenv('HOST', '0.0.0.0')

@app.route('/v1/test')
def test_route():
    return 'This is Salt Security'

@app.route('/v1/health')
def health_route():
    return '', 200

if __name__ == '__main__':
    app.run(host=host, port=port)
