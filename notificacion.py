from plyer import notification
import sys

def mostrar_notificacion(titulo, mensaje):
    notification.notify(
        title=titulo,
        message=mensaje,
        app_name="Tecnosoft",
        timeout=5,
    )

if __name__ == "__main__":
    # El título y mensaje se pasan como argumentos
    titulo = sys.argv[1]
    mensaje = sys.argv[2]
    mostrar_notificacion(titulo, mensaje)
