import random
import mysql.connector

# Configuración de conexión a la base de datos
config = {
    'user': 'root',
    'password': 'rootpassword',
    'host': 'localhost',
    'database': 'dashboard'
}

# Conectar a la base de datos
try:
    connection = mysql.connector.connect(**config)
    cursor = connection.cursor()
    
    NULL = None
    rango = 13 #por cada autoevaluacion + 1
    total_factores = 12
    numero_base = rango * total_factores

    # Datos originales
    calificacion_caracteristica_data_original = [
    (1, None, 0, 4.15, 1),
    (2, None, 0, 4.15, 2),
    (3, None, 0, 1.66, 2),
    (4, None, 0, 1.66, 2),
    (5, None, 0, 1.66, 2),
    (6, None, 0, 1.66, 2),
    (7, None, 0, 1.66, 2),
    (8, None, 0, 1.38, 3),
    (9, None, 0, 1.38, 3),
    (10, None, 0, 1.38, 3),
    (11, None, 0, 1.38, 3),
    (12, None, 0, 1.38, 3),
    (13, None, 0, 1.38, 3),
    (16, None, 0, 4.15, 4),
    (17, None, 0, 4.15, 4),
    (18, None, 0, 1.38, 5),
    (19, None, 0, 1.38, 5),
    (20, None, 0, 1.38, 5),
    (21, None, 0, 1.38, 5),
    (22, None, 0, 1.38, 5),
    (23, None, 0, 1.38, 5),
    (27, None, 0, 2.08, 6),
    (28, None, 0, 2.08, 6),
    (29, None, 0, 2.08, 6),
    (30, None, 0, 2.08, 6),
    (31, None, 0, 2.77, 7),
    (32, None, 0, 2.77, 7),
    (33, None, 0, 2.77, 7),
    (34, None, 0, 4.15, 8),
    (35, None, 0, 4.15, 8),
    (36, None, 0, 4.15, 9),
    (37, None, 0, 4.15, 9),
    (38, None, 0, 2.77, 10),
    (39, None, 0, 2.77, 10),
    (40, None, 0, 2.77, 10),
    (41, None, 0, 1.38, 11),
    (42, None, 0, 1.38, 11),
    (43, None, 0, 1.38, 11),
    (44, None, 0, 1.38, 11),
    (45, None, 0, 1.38, 11),
    (46, None, 0, 1.38, 11),
    (47, None, 0, 4.15, 12),
    (48, None, 0, 4.15, 12),
    ]

    # Sumar el numero_base a la última posición de cada fila
    calificacion_caracteristica_data = [
        (factor_id, autoevaluacion_id, round(random.uniform(3, 5), 2), cal2, valor + numero_base)
        for factor_id, autoevaluacion_id, cal1, cal2, valor in calificacion_caracteristica_data_original
    ]

    # Imprimir el resultado
    for row in calificacion_caracteristica_data:
        print(row)

    # Insertar en calificacion_caracteristica
    cursor.executemany(
        "INSERT INTO calificacion_caracteristica (caracteristica_id, justificacion, resultado, ponderacion, calificacion_factor_id) VALUES (%s, %s, %s, %s, %s)",
        calificacion_caracteristica_data
    )

    # Confirmar los cambios
    connection.commit()
    print("Datos insertados exitosamente.")

except mysql.connector.Error as err:
    print(f"Error: {err}")
finally:
    if 'cursor' in locals():
        cursor.close()
    if 'connection' in locals():
        connection.close()