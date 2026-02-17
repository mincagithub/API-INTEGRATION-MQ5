from modification_ini import update_ini, update_ini_MT4
from extract_accounts import get_accounts, is_account_permitted
from Send import Ejecute_shell
from datetime import datetime
import time

HORA_PROGRAMADA = "18:00"   # 🔥 Cambia aquí la hora fija


def scheduler_loop():
    last_run_time = None
    print(f"⏳ Esperando la hora {HORA_PROGRAMADA}...")

    while True:
        ahora = datetime.now().strftime("%H:%M")

        if ahora == HORA_PROGRAMADA and last_run_time != ahora:

            print(f"🚀 Ejecutando ciclo a las {HORA_PROGRAMADA}")

            accounts_total = get_accounts()

            if not accounts_total:
                print("⚠️ No hay cuentas configuradas.")
            else:
                for acc in accounts_total:
                    acc_id     = acc["id"]
                    acc_pass   = acc["password"]
                    acc_server = acc["server"]
                    acc_type   = acc["tipo"]

                    print("acc_id: ", acc_id)
                    print("acc_pass: ", acc_pass)
                    print("acc_server: ", acc_server)
                    print("acc_type: ", acc_type)

                    if not is_account_permitted(acc_id):
                        print(f"❌ Cuenta {acc_id} no permitida.")
                        continue

                    print(f"➡️ Procesando {acc_id} ({acc_type})")

                    if acc_type.upper() == "MT5":
                        update_ini(acc_id, acc_server, acc_pass)
                    else:
                        update_ini_MT4(acc_id, acc_server, acc_pass)

                    Ejecute_shell(acc_type)
                    time.sleep(5)

            last_run_time = ahora
            print("✅ Ciclo finalizado. Esperando próximo día...")

        time.sleep(10)


if __name__ == "__main__":
    scheduler_loop()






"""
from flask import Flask, request
from sheets_writer import send_to_sheet, normalize_date
from Send import Ejecute_shell
from modification_ini import update_ini, update_ini_MT4
from extract_accounts import get_accounts, is_account_permitted
from datetime import datetime
import threading
import time

app = Flask(__name__)

# --- variable global para sincronizar ---
last_received_id = None

# --- Flask endpoint ---
@app.route("/mt5data", methods=["GET"])
def receive_data():
    global last_received_id

    account_id  = request.args.get("AccountID")
    date        = normalize_date(request.args.get("Date"))
    balance     = request.args.get("Balance")
    profit      = request.args.get("Profit")
    percent     = request.args.get("Percent")
    date_f      = datetime.now().strftime("%Y/%m/%d")

    print(f"Cuenta: {account_id}, Fecha: {date_f}, Balance: {balance}, Profit: {profit}, Percent {percent}")

      # ✅ validar antes de mandar a Google Sheets y antes de tocar last_received_id
    if not is_account_permitted(account_id):
        return "Forbidden Account", 403

    
    try:
        send_to_sheet(account_id, date_f, balance, profit, percent)
    except Exception as e:
        print("⚠️ Error al enviar a Google Sheets:", e)

    # guardamos el último account_id recibido
    last_received_id = account_id

    return "OK", 200


permit = True
last_run_time = None  # guarda última hora HH:MM en que se ejecutó

def scheduler_loop(hora_programada: str):
    global permit, last_run_time, last_received_id
    print(f"Ejecutor en background esperando la hora {hora_programada}...")

    while True:
        ahora = datetime.now().strftime("%H:%M")

        if ahora == hora_programada and permit:
            if last_run_time == ahora:
                time.sleep(5)
                continue

            print(f"Llegó a la hora esperada {hora_programada}")

            accounts_total = get_accounts()
            if not accounts_total:
                print("⚠️ No hay cuentas configuradas en cuentas_mt5.")
            else:
                permit = False
                for acc in accounts_total:
                    acc_id      = acc["id"]
                    acc_pass    = acc["password"]
                    acc_server  = acc["server"]
                    acc_type    = acc["tipo"]

                    #if acc_id != "50511908":
                    #    continue

                    print(f"➡️ Procesando cuenta: {acc_id} de {acc_type}")

                    if not is_account_permitted(acc_id):
                        print(f"❌ Cuenta {acc_id} no está permitida, se omite ejecución......")
                        continue
                    
                    if acc_type.upper() == "MT5":
                        update_ini(acc_id, acc_server, acc_pass)
                        Ejecute_shell(acc_type)
                        matched = False
                        for i in range(25):
                            if last_received_id == acc_id:
                                print(f"✅ Confirmación recibida para cuenta {acc_id}")
                                matched = True
                                break
                            time.sleep(2)
                        if not matched:
                            print(f"⚠️ No se recibió confirmación para {acc_id} tras 30s, avanzando...")
                        time.sleep(5)
                    else:
                        update_ini_MT4(acc_id, acc_server, acc_pass)
                        Ejecute_shell(acc_type)
                        time.sleep(5)

                permit = True
                last_run_time = ahora
                print(f"✅ Finalizado. No volverá a ejecutarse hasta la próxima vez que llegue {hora_programada} mañana.")

        else:
            # reiniciar last_run_time cuando cambie la hora
            if last_run_time and ahora != last_run_time:
                last_run_time = None
            time.sleep(5)


if __name__ == "__main__":
    hora_input = input("⏰ Ingresa la hora de ejecución (HH:MM): ").strip()
    try:
        datetime.strptime(hora_input, "%H:%M")
    except ValueError:
        print("❌ Formato inválido. Usa HH:MM (ej: 14:30).")
        exit(1)

    # Lanzar el loop en un hilo
    t = threading.Thread(target=scheduler_loop, args=(hora_input,), daemon=True)
    t.start()

    # Arrancar Flask
    app.run(host="127.0.0.1", port=80, debug=False, use_reloader=False)


#127.0.0.1 - - [09/Oct/2025 22:30:14] "GET /mt5data?AccountID=50511908&Date=2025.10.09&Balance=2400.00&Profit=0.00&Percent=0.00 HTTP/1.1" 200 -
"""