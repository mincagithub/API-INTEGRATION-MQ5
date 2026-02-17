import gspread
from oauth2client.service_account import ServiceAccountCredentials
import os

# --- Autenticación con Google Sheets ---
scope = ["https://spreadsheets.google.com/feeds",
         "https://www.googleapis.com/auth/drive"]

# Ruta al archivo JSON con credenciales
config_path = os.path.join(os.path.dirname(__file__), "google_service_key.json")
creds       = ServiceAccountCredentials.from_json_keyfile_name(config_path, scope)
client      = gspread.authorize(creds)

# --- Seleccionar la hoja cuentas_mt5 ---
sheet = client.open("OLSO ACCOUNTS").worksheet("cuentas_mt5")

def get_accounts():
    """
    Lee la hoja 'cuentas_mt5' y devuelve una lista de diccionarios:
      - id
      - password
      - server
      - tipo (MT4 o MT5)

    La lectura empieza en la fila 2 (fila 1 = cabecera)  
    y se detiene al encontrar la primera fila vacía.
    """
    accounts = []
    rows     = sheet.get_all_values()

    for row in rows[1:]:  # Saltar cabecera
        if not row or not row[0].strip():
            break  # Detener si encuentra fila vacía en la columna A

        account = {
            "id"        : row[0].strip(),
            "password"  : row[1] if len(row) > 1 else "",
            "server"    : row[2] if len(row) > 2 else "",
            "tipo"      : row[3].upper() if len(row) > 3 else "MT5"  # Default MT5
        }
        accounts.append(account)

    return accounts


def is_account_permitted(account_id: str, tipo: str = None) -> bool:
    """
    Retorna True si el account_id existe en la hoja 'cuentas_mt5'.
    Si se pasa 'tipo', también valida que coincida (MT4 o MT5).
    """
    accounts = get_accounts()
    for acc in accounts:
        if acc["id"] == str(account_id):
            if tipo:
                return acc["tipo"] == tipo.upper()
            return True
    return False