# This is just to be able to load the mixcloud.html file over HTTPS with any
# path, so that the HTML can be easily tested.
import http.server
import socketserver
import ssl

class SingleFileHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.path = '/mixcloud.html'  # Replace with your file name
        return super().do_GET()

PORT = 8000
DIRECTORY = '.'  # Replace with the directory containing your file
CERT_FILE = "certificate.pem"
KEY_FILE = "key.pem"

Handler = SingleFileHandler
Handler.directory = DIRECTORY

# Create an SSL context
ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
ssl_context.load_cert_chain(certfile=CERT_FILE, keyfile=KEY_FILE)

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    # Wrap the server with SSL
    httpd.socket = ssl_context.wrap_socket(
        httpd.socket,
        server_side=True,
    )
    print(f"Serving HTTPS on port {PORT}")
    httpd.serve_forever()