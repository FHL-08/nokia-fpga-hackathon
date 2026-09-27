import vitis
import shutil
import os
client = vitis.create_client()

client.update_workspace("./workspace")

platform = client.create_platform_component(name='platform', 
                                            hw_design="microblaze_system_wrapper.xsa",
                                            os="standalone",
                                            cpu="microblaze_0")

app = client.get_component(name="app")

