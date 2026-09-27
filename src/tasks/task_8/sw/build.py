import vitis

client = vitis.create_client()

client.update_workspace("./workspace")

platform = client.get_component(name="platform")
platform.build()

app = client.get_component(name="app")
app.build()

