import mysql.connector

# Configuración de conexión a la base de datos
config = {
    'user': 'root',
    'password': 'rootpassword',
    'host': 'localhost',
    'database': 'acreditacion_arcadia_dashboard'
}

# Conectar a la base de datos
try:
    connection = mysql.connector.connect(**config)
    cursor = connection.cursor()

    
    
    NULL = None
    numero_base = 48

    # Datos originales
    calificacion_caracteristica_data_original = [
        (1, None, 3.50, 4.15, 1),
        (2, None, 3.00, 4.15, 2),
        (3, None, 3.30, 1.66, 2),
        (4, None, 3.50, 1.66, 2),
        (5, None, 3.50, 1.66, 2), 
        (6, None, 3.00, 1.66, 2),
        (7, None, 4.50, 1.66, 2),
        (8, None, 2.80, 1.38, 3),
        (9, None, 3.20, 1.38, 3),
        (10, None, 4.50, 1.38, 3),
        (11, None, 4.90, 1.38, 3),
        (12, None, 3.20, 1.38, 3),
        (13, None, 5.00, 1.38, 3),
        (16, None, 3.00, 4.15, 4),
        (17, None, 3.50, 4.15, 4),
        (18, None, 5.00, 1.38, 5),
        (19, None, 3.00, 1.38, 5),
        (20, None, 4.00, 1.38, 5),
        (21, None, 4.00, 1.38, 5),
        (22, None, 4.50, 1.38, 5),
        (23, None, 2.50, 1.38, 5),
        (27, None, 3.00, 2.08, 6),
        (28, None, 4.00, 2.08, 6),
        (29, None, 3.50, 2.08, 6),
        (30, None, 4.80, 2.08, 6),
        (31, None, 2.00, 2.77, 7),
        (32, None, 3.50, 2.77, 7),
        (33, None, 5.00, 2.77, 7),
        (34, None, 4.50, 4.15, 8),
        (35, None, 4.00, 4.15, 8),
        (36, None, 3.00, 4.15, 9),
        (37, None, 3.00, 4.15, 9),
        (38, None, 3.50, 2.77, 10),
        (39, None, 4.00, 2.77, 10),
        (40, None, 5.00, 2.77, 10),
        (41, None, 3.00, 1.38, 11),
        (42, None, 4.50, 1.38, 11),
        (43, None, 4.30, 1.38, 11),
        (44, None, 1.50, 1.38, 11),
        (45, None, 5.00, 1.38, 11),
        (46, None, 2.00, 1.38, 11),
        (47, None, 3.00, 4.15, 12),
        (48, None, 5.00, 4.15, 12),
    ]

    # Sumar el numero_base a la última posición de cada fila
    calificacion_caracteristica_data = [
        (factor_id, autoevaluacion_id, cal1, cal2, valor + numero_base)
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
