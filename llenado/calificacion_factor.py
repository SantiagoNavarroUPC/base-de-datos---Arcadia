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
    rango = 13
    numero_base = rango * 12
    
    calificacion_factor_data_original = [
    (1, 1, 8.3, NULL, 1),
    (2, 2, 8.3, NULL, 1),
    (3, 3, 8.3, NULL, 1),
    (4, 4, 8.3, NULL, 1),
    (5, 5, 8.3, NULL, 1),
    (6, 6, 8.3, NULL, 1),
    (7, 7, 8.3, NULL, 1),
    (8, 8, 8.3, NULL, 1),
    (9, 9, 8.3, NULL, 1),
    (10, 10, 8.3, NULL, 1),
    (11, 11, 8.3, NULL, 1),
    (12, 12, 8.3, NULL, 1),
    ]

    # Sumar el numero_base a la última posición de cada fila
    calificacion_factor_data = [
        (valor + numero_base,factor_id, ponderacion, resultado, autoevaluacion_id + rango)
        for valor, factor_id, ponderacion, resultado,autoevaluacion_id  in calificacion_factor_data_original
    ]

    # Imprimir el resultado
    for row in calificacion_factor_data:
        print(row)

    # Insertar en calificacion_caracteristica
    cursor.executemany(
        "INSERT INTO `calificacion_factor` (`calificacion_factor_id`, `factor_id`, `ponderacion`, `resultado`, `autoevaluacion_id`) VALUES (%s, %s, %s, %s, %s)",
        calificacion_factor_data
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
