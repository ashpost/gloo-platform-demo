from locust import FastHttpUser, task

class GlooGatewayUser(FastHttpUser):
    def on_start(self):
        """ on_start is called when a Locust start before any task is scheduled """
        self.client.verify = False

    @task
    def productpage(self):
        self.client.get("/productpage")
        self.client.get("/get")
