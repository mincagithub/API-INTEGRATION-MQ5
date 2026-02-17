import configparser
import os

def update_ini(login: str, server: str, password: str, ini_path: str = None):
    """
    Modifica los valores de Login, Server y Password en el archivo confi.ini.

    :param login: Nuevo valor para Login
    :param server: Nuevo valor para Server
    :param password: Nuevo valor para Password
    :param ini_path: Ruta del archivo confi.ini (por defecto, mismo directorio del script)
    """

    if ini_path is None:
        ini_path = os.path.join(os.path.dirname(__file__), "confi.ini")

    # Leer archivo .ini
    config = configparser.ConfigParser()
    config.optionxform = str 
    config.read(ini_path)

    # Modificar solo los valores de la sección [Common]
    if "Common" not in config:
        raise ValueError("❌ El archivo ini no contiene la sección [Common].")

    config["Common"]["Login"]       = str(login)
    config["Common"]["Server"]      = server
    config["Common"]["Password"]    = password

    Final = "EURUSD"
    if server == "ADNBrokerCFD-Server":
        Final = "EURUSD.b"

    if server == "TagMarkets-Server":
        Final = "EURUSD.f"
    
    if server == "VT markets live":
        Final = "EURUSD-ECN"

    
    config["StartUp"]["Symbol"]      = Final

    # Guardar cambios
    with open(ini_path, "w") as configfile:
        config.write(configfile)



def update_ini_MT4(login: str, server: str, password: str, ini_path: str = None):
    """
    Modifica los valores de Login, Server y Password en el archivo confiMT4.ini.

    :param login: Nuevo valor para Login
    :param server: Nuevo valor para Server
    :param password: Nuevo valor para Password
    :param ini_path: Ruta del archivo confiMT4.ini (por defecto, mismo directorio del script)
    """

    if ini_path is None:
        ini_path = os.path.join(os.path.dirname(__file__), "confiMT4.ini")

    # Leer todas las líneas del archivo
    with open(ini_path, "r", encoding="utf-8") as f:
        lineas = f.readlines()

    nuevas_lineas   = []
    Final           = "EURUSD"

    for linea in lineas:
        if linea.startswith("Login="):
            nuevas_lineas.append(f"Login={login}\n")
        elif linea.startswith("Server="):
            nuevas_lineas.append(f"Server={server}\n")
        elif linea.startswith("Password="):
            nuevas_lineas.append(f"Password={password}\n")
        elif linea.startswith("Symbol="):
            nuevas_lineas.append(f"Symbol={Final}\n")
        else:
            nuevas_lineas.append(linea)

    # Sobrescribir el archivo con los cambios
    with open(ini_path, "w", encoding="utf-8") as f:
        f.writelines(nuevas_lineas)