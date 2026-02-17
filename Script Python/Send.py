import subprocess
import os
import time

def Ejecute_shell(tipo: str = "MT5"):

    """
    Lanza MetaTrader con el confi.ini según el tipo (MT4 o MT5).
    """

    if tipo.upper() == "MT4":
        terminal_path   = r"C:\Program Files (x86)\MetaTrader 4 Axi Terminal\terminal.exe"
        config_path     = os.path.join(os.path.dirname(__file__), "confiMT4.ini")
        command         = [terminal_path, config_path]

        try:
            process = subprocess.Popen(command)
            print("MT4 process:", process)

            time.sleep(40)
            process.terminate()   
        except Exception as e:
            print(f"❌ Error al iniciar: {e}")

    else:  
        terminal_path   = r"C:\Program Files\MetaTrader 5\terminal64.exe"
        config_path     = os.path.join(os.path.dirname(__file__), "confi.ini")
        command         = f'"{terminal_path}" /config:{config_path}'

        try:
            process = subprocess.Popen(command, shell=True)
            print(f"{tipo.upper()} iniciado con el archivo de configuración:", config_path)
            print("MT5 process:", process)
        except Exception as e:
            print(f"❌ Error al iniciar {tipo.upper()}:", e)