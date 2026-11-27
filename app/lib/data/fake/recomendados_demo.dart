// GENERADO: no editar a mano.
//
// Los 100 hábitos recomendados tal como lo devuelve `GET /habitos/recomendados` (contrato v1.7), con los MISMOS ids
// que el clúster (las categorías y subcategorías, de catalogo_demo.dart; las recomendaciones, de md5 de su clave).
// Sale de la base (db/cambios/2026-11-27_recomendaciones.sql) con la consulta de `app/docs/modulos/09_identidad_visual.md`.
// ignore_for_file: lines_longer_than_80_chars

const String recomendadosDemoJson = r'''
[
 {
  "id": "e34965d9-e9ee-9413-31db-81d7be7fef64",
  "clave": "caminar_rapido",
  "nombre": "Caminar a paso rápido",
  "categoria": {
   "id": "ed1867f2-83b3-45a9-b27e-4f650f36c275",
   "clave": "ejercicio",
   "nombre": "Ejercicio",
   "color": "#D9480F",
   "icono": "fitness_center"
  },
  "subcategoria": {
   "id": "d851b381-e60e-44cc-8bfe-1b9ec18487b1",
   "clave": "aerobico_moderado",
   "nombre": "Aeróbico moderado",
   "icono": "directions_bike",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 30.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 31,
   "veces_semana": null
  },
  "momento": "Después de comer",
  "porque": "La OMS recomienda de 150 a 300 minutos de actividad moderada a la semana. 30 minutos de lunes a viernes llegan a 150.",
  "fuentes": "F11",
  "zona": "optimo",
  "optimo_desde": 30.0,
  "optimo_hasta": 60.0
 },
 {
  "id": "becffece-9853-7cb6-435c-2a6019ff68b9",
  "clave": "andar_bicicleta",
  "nombre": "Andar en bicicleta",
  "categoria": {
   "id": "ed1867f2-83b3-45a9-b27e-4f650f36c275",
   "clave": "ejercicio",
   "nombre": "Ejercicio",
   "color": "#D9480F",
   "icono": "fitness_center"
  },
  "subcategoria": {
   "id": "d851b381-e60e-44cc-8bfe-1b9ec18487b1",
   "clave": "aerobico_moderado",
   "nombre": "Aeróbico moderado",
   "icono": "directions_bike",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 50.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 21,
   "veces_semana": null
  },
  "momento": "Al salir del trabajo o la escuela",
  "porque": "Pedalear a ritmo moderado cuenta para los 150 a 300 minutos semanales: 3 salidas de 50 minutos dan 150.",
  "fuentes": "F11",
  "zona": "optimo",
  "optimo_desde": 50.0,
  "optimo_hasta": 100.0
 },
 {
  "id": "fd800e1e-ac64-36b5-d031-61c08ad78ad1",
  "clave": "bailar",
  "nombre": "Bailar",
  "categoria": {
   "id": "ed1867f2-83b3-45a9-b27e-4f650f36c275",
   "clave": "ejercicio",
   "nombre": "Ejercicio",
   "color": "#D9480F",
   "icono": "fitness_center"
  },
  "subcategoria": {
   "id": "d851b381-e60e-44cc-8bfe-1b9ec18487b1",
   "clave": "aerobico_moderado",
   "nombre": "Aeróbico moderado",
   "icono": "directions_bike",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 30.0,
  "frecuencia": {
   "tipo": "n_por_semana",
   "dias_semana": null,
   "veces_semana": 5
  },
  "momento": "Después de cenar",
  "porque": "Cualquier actividad que acelere tu respiración cuenta como moderada: 30 minutos 5 veces a la semana cumplen lo mínimo.",
  "fuentes": "F11",
  "zona": "optimo",
  "optimo_desde": 30.0,
  "optimo_hasta": 60.0
 },
 {
  "id": "2ebf76cb-7878-7819-03b8-80c0d0d57ad6",
  "clave": "nadar",
  "nombre": "Nadar",
  "categoria": {
   "id": "ed1867f2-83b3-45a9-b27e-4f650f36c275",
   "clave": "ejercicio",
   "nombre": "Ejercicio",
   "color": "#D9480F",
   "icono": "fitness_center"
  },
  "subcategoria": {
   "id": "d851b381-e60e-44cc-8bfe-1b9ec18487b1",
   "clave": "aerobico_moderado",
   "nombre": "Aeróbico moderado",
   "icono": "directions_bike",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 45.0,
  "frecuencia": {
   "tipo": "n_por_semana",
   "dias_semana": null,
   "veces_semana": 4
  },
  "momento": "Por la mañana, antes de tus pendientes",
  "porque": "Nadar a ritmo tranquilo es actividad moderada: 45 minutos 4 veces a la semana dan 180, dentro de lo recomendado.",
  "fuentes": "F11",
  "zona": "optimo",
  "optimo_desde": 37.5,
  "optimo_hasta": 75.0
 },
 {
  "id": "067b16ef-1400-11ab-7dcb-5d441eb6685a",
  "clave": "correr",
  "nombre": "Correr",
  "categoria": {
   "id": "ed1867f2-83b3-45a9-b27e-4f650f36c275",
   "clave": "ejercicio",
   "nombre": "Ejercicio",
   "color": "#D9480F",
   "icono": "fitness_center"
  },
  "subcategoria": {
   "id": "78557c27-d715-414a-b911-f10edebc8244",
   "clave": "vigoroso",
   "nombre": "Vigoroso",
   "icono": "directions_run",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 25.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 21,
   "veces_semana": null
  },
  "momento": "Al despertar",
  "porque": "En lugar de la actividad moderada, la OMS acepta de 75 a 150 minutos de actividad vigorosa a la semana.",
  "fuentes": "F11",
  "zona": "optimo",
  "optimo_desde": 25.0,
  "optimo_hasta": 50.0
 },
 {
  "id": "5b013c73-76c9-17a3-7ce6-fd5668a03b8e",
  "clave": "intervalos",
  "nombre": "Entrenamiento por intervalos",
  "categoria": {
   "id": "ed1867f2-83b3-45a9-b27e-4f650f36c275",
   "clave": "ejercicio",
   "nombre": "Ejercicio",
   "color": "#D9480F",
   "icono": "fitness_center"
  },
  "subcategoria": {
   "id": "78557c27-d715-414a-b911-f10edebc8244",
   "clave": "vigoroso",
   "nombre": "Vigoroso",
   "icono": "directions_run",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 20.0,
  "frecuencia": {
   "tipo": "n_por_semana",
   "dias_semana": null,
   "veces_semana": 4
  },
  "momento": "Antes de bañarte",
  "porque": "Los intervalos intensos son actividad vigorosa: 20 minutos 4 veces a la semana pasan de los 75 recomendados.",
  "fuentes": "F11",
  "zona": "optimo",
  "optimo_desde": 18.75,
  "optimo_hasta": 37.5
 },
 {
  "id": "fedf9ed8-459e-72d5-0d56-7a8bdadd3c49",
  "clave": "deporte_equipo",
  "nombre": "Jugar fútbol o básquetbol",
  "categoria": {
   "id": "ed1867f2-83b3-45a9-b27e-4f650f36c275",
   "clave": "ejercicio",
   "nombre": "Ejercicio",
   "color": "#D9480F",
   "icono": "fitness_center"
  },
  "subcategoria": {
   "id": "78557c27-d715-414a-b911-f10edebc8244",
   "clave": "vigoroso",
   "nombre": "Vigoroso",
   "icono": "directions_run",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 50.0,
  "frecuencia": {
   "tipo": "n_por_semana",
   "dias_semana": null,
   "veces_semana": 2
  },
  "momento": "El fin de semana, con tu equipo",
  "porque": "Los deportes de equipo son actividad vigorosa: dos partidos de 50 minutos dan 100 a la semana.",
  "fuentes": "F11",
  "zona": "optimo",
  "optimo_desde": 37.5,
  "optimo_hasta": 75.0
 },
 {
  "id": "0b8e027e-a321-fb38-5cc4-a5bc79c9ebfb",
  "clave": "fuerza_casa",
  "nombre": "Ejercicios de fuerza en casa",
  "categoria": {
   "id": "ed1867f2-83b3-45a9-b27e-4f650f36c275",
   "clave": "ejercicio",
   "nombre": "Ejercicio",
   "color": "#D9480F",
   "icono": "fitness_center"
  },
  "subcategoria": {
   "id": "d7366413-4c61-4b7e-b39f-1cc0dc0ce925",
   "clave": "fuerza",
   "nombre": "Fuerza",
   "icono": "fitness_center",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 20.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 9,
   "veces_semana": null
  },
  "momento": "Después de caminar",
  "porque": "La OMS pide fortalecer los músculos al menos 2 días por semana; de 30 a 60 minutos semanales dan el mayor beneficio.",
  "fuentes": "F11, F14",
  "zona": "optimo",
  "optimo_desde": 15.0,
  "optimo_hasta": 30.0
 },
 {
  "id": "0d800da4-0ce7-fe51-dd41-a4bf09d6a4f4",
  "clave": "levantar_pesas",
  "nombre": "Levantar pesas",
  "categoria": {
   "id": "ed1867f2-83b3-45a9-b27e-4f650f36c275",
   "clave": "ejercicio",
   "nombre": "Ejercicio",
   "color": "#D9480F",
   "icono": "fitness_center"
  },
  "subcategoria": {
   "id": "d7366413-4c61-4b7e-b39f-1cc0dc0ce925",
   "clave": "fuerza",
   "nombre": "Fuerza",
   "icono": "fitness_center",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 25.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 10,
   "veces_semana": null
  },
  "momento": "Después del trabajo",
  "porque": "Dos sesiones de 25 minutos caen en los 30 a 60 minutos semanales con mayor beneficio.",
  "fuentes": "F11, F14",
  "zona": "optimo",
  "optimo_desde": 15.0,
  "optimo_hasta": 30.0
 },
 {
  "id": "3bdfcc76-e740-083c-315b-22cdaa821086",
  "clave": "fuerza_ligas",
  "nombre": "Fuerza con ligas",
  "categoria": {
   "id": "ed1867f2-83b3-45a9-b27e-4f650f36c275",
   "clave": "ejercicio",
   "nombre": "Ejercicio",
   "color": "#D9480F",
   "icono": "fitness_center"
  },
  "subcategoria": {
   "id": "d7366413-4c61-4b7e-b39f-1cc0dc0ce925",
   "clave": "fuerza",
   "nombre": "Fuerza",
   "icono": "fitness_center",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 15.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 21,
   "veces_semana": null
  },
  "momento": "Al despertar",
  "porque": "Tres sesiones cortas de 15 minutos suman 45 a la semana, dentro del rango con más beneficio.",
  "fuentes": "F11, F14",
  "zona": "optimo",
  "optimo_desde": 10.0,
  "optimo_hasta": 20.0
 },
 {
  "id": "734bfe42-96bb-454c-31c1-7a530c117bde",
  "clave": "sentadillas_lagartijas",
  "nombre": "Sentadillas y lagartijas",
  "categoria": {
   "id": "ed1867f2-83b3-45a9-b27e-4f650f36c275",
   "clave": "ejercicio",
   "nombre": "Ejercicio",
   "color": "#D9480F",
   "icono": "fitness_center"
  },
  "subcategoria": {
   "id": "d7366413-4c61-4b7e-b39f-1cc0dc0ce925",
   "clave": "fuerza",
   "nombre": "Fuerza",
   "icono": "fitness_center",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 10.0,
  "frecuencia": {
   "tipo": "n_por_semana",
   "dias_semana": null,
   "veces_semana": 3
  },
  "momento": "Antes de bañarte",
  "porque": "Aun 30 minutos de fuerza a la semana reducen el riesgo; repartirlos en 3 días te da tiempo de recuperarte.",
  "fuentes": "F14",
  "zona": "optimo",
  "optimo_desde": 10.0,
  "optimo_hasta": 20.0
 },
 {
  "id": "c4e71a50-8ba3-d64a-a885-9c0bf62b653f",
  "clave": "pasos_8000",
  "nombre": "Caminar 8,000 pasos",
  "categoria": {
   "id": "ed1867f2-83b3-45a9-b27e-4f650f36c275",
   "clave": "ejercicio",
   "nombre": "Ejercicio",
   "color": "#D9480F",
   "icono": "fitness_center"
  },
  "subcategoria": {
   "id": "6184a58c-a1fc-41ca-a246-35455dd2ddad",
   "clave": "pasos",
   "nombre": "Pasos",
   "icono": "directions_walk",
   "sentido": "aumentar"
  },
  "unidad": "pasos",
  "meta": 8000.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Durante el día, en traslados y pausas",
  "porque": "El beneficio de caminar crece hasta los 8,000 a 10,000 pasos al día (de 6,000 a 8,000 después de los 60).",
  "fuentes": "F15",
  "zona": "optimo",
  "optimo_desde": 8000.0,
  "optimo_hasta": 10000.0
 },
 {
  "id": "84d74f03-f19b-7366-b773-16f74bc3e5b3",
  "clave": "pasos_10000",
  "nombre": "Caminar 10,000 pasos",
  "categoria": {
   "id": "ed1867f2-83b3-45a9-b27e-4f650f36c275",
   "clave": "ejercicio",
   "nombre": "Ejercicio",
   "color": "#D9480F",
   "icono": "fitness_center"
  },
  "subcategoria": {
   "id": "6184a58c-a1fc-41ca-a246-35455dd2ddad",
   "clave": "pasos",
   "nombre": "Pasos",
   "icono": "directions_walk",
   "sentido": "aumentar"
  },
  "unidad": "pasos",
  "meta": 10000.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Con una caminata después de cenar",
  "porque": "Llegar a 10,000 pasos al día está en el rango donde el beneficio de caminar se estabiliza.",
  "fuentes": "F15",
  "zona": "optimo",
  "optimo_desde": 8000.0,
  "optimo_hasta": 10000.0
 },
 {
  "id": "96bd9176-e87c-2e89-2f2f-567522511820",
  "clave": "pasos_9000_semana",
  "nombre": "Caminar 9,000 pasos entre semana",
  "categoria": {
   "id": "ed1867f2-83b3-45a9-b27e-4f650f36c275",
   "clave": "ejercicio",
   "nombre": "Ejercicio",
   "color": "#D9480F",
   "icono": "fitness_center"
  },
  "subcategoria": {
   "id": "6184a58c-a1fc-41ca-a246-35455dd2ddad",
   "clave": "pasos",
   "nombre": "Pasos",
   "icono": "directions_walk",
   "sentido": "aumentar"
  },
  "unidad": "pasos",
  "meta": 9000.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 31,
   "veces_semana": null
  },
  "momento": "Bajándote una parada antes o usando escaleras",
  "porque": "Entre 8,000 y 10,000 pasos al día es lo que más beneficio da antes de los 60 años.",
  "fuentes": "F15",
  "zona": "optimo",
  "optimo_desde": 8000.0,
  "optimo_hasta": 10000.0
 },
 {
  "id": "44de33f7-fbf6-b977-d276-fe33d3b3ca22",
  "clave": "estirar_despues",
  "nombre": "Estirar después de ejercitarte",
  "categoria": {
   "id": "ed1867f2-83b3-45a9-b27e-4f650f36c275",
   "clave": "ejercicio",
   "nombre": "Ejercicio",
   "color": "#D9480F",
   "icono": "fitness_center"
  },
  "subcategoria": {
   "id": "34b5aca8-cb1a-45f7-9f63-b454c535e477",
   "clave": "estiramiento",
   "nombre": "Estiramiento",
   "icono": "accessibility_new",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 10.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 21,
   "veces_semana": null
  },
  "momento": "Después de ejercitarte",
  "porque": "Estirar los grupos musculares grandes al menos 2 o 3 días por semana mejora la flexibilidad.",
  "fuentes": "F16",
  "zona": "optimo",
  "optimo_desde": 6.67,
  "optimo_hasta": 23.33
 },
 {
  "id": "64956c4b-306a-9a71-a3ee-76993d628a1c",
  "clave": "estirar_manana",
  "nombre": "Estirar cada mañana",
  "categoria": {
   "id": "ed1867f2-83b3-45a9-b27e-4f650f36c275",
   "clave": "ejercicio",
   "nombre": "Ejercicio",
   "color": "#D9480F",
   "icono": "fitness_center"
  },
  "subcategoria": {
   "id": "34b5aca8-cb1a-45f7-9f63-b454c535e477",
   "clave": "estiramiento",
   "nombre": "Estiramiento",
   "icono": "accessibility_new",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 10.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Al despertar",
  "porque": "Estirar a diario da más efecto que hacerlo solo 2 o 3 días por semana.",
  "fuentes": "F16",
  "zona": "optimo",
  "optimo_desde": 2.86,
  "optimo_hasta": 10.0
 },
 {
  "id": "17b329a3-54c7-e987-2a15-dbd432d6d025",
  "clave": "yoga_suave",
  "nombre": "Yoga suave",
  "categoria": {
   "id": "ed1867f2-83b3-45a9-b27e-4f650f36c275",
   "clave": "ejercicio",
   "nombre": "Ejercicio",
   "color": "#D9480F",
   "icono": "fitness_center"
  },
  "subcategoria": {
   "id": "34b5aca8-cb1a-45f7-9f63-b454c535e477",
   "clave": "estiramiento",
   "nombre": "Estiramiento",
   "icono": "accessibility_new",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 20.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 10,
   "veces_semana": null
  },
  "momento": "Antes de dormir",
  "porque": "Las posturas sostenidas cuentan como estiramiento: 2 sesiones de 20 minutos dan 40 a la semana.",
  "fuentes": "F16",
  "zona": "optimo",
  "optimo_desde": 10.0,
  "optimo_hasta": 35.0
 },
 {
  "id": "2fa9b9fa-48cb-9e0a-238f-a32e8f139dc1",
  "clave": "pausa_cada_hora",
  "nombre": "Pausa activa cada hora",
  "categoria": {
   "id": "ed1867f2-83b3-45a9-b27e-4f650f36c275",
   "clave": "ejercicio",
   "nombre": "Ejercicio",
   "color": "#D9480F",
   "icono": "fitness_center"
  },
  "subcategoria": {
   "id": "c91f57b0-2064-42c6-a390-ff9f23fbe86d",
   "clave": "pausas_activas",
   "nombre": "Pausas activas",
   "icono": "timer",
   "sentido": "aumentar"
  },
  "unidad": "pausas",
  "meta": 8.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 31,
   "veces_semana": null
  },
  "momento": "Cada hora que pases sentado",
  "porque": "Levantarte un par de minutos cada cierto tiempo mejora tu glucosa después de comer.",
  "fuentes": "F11, F17",
  "zona": "optimo",
  "optimo_desde": 8.0,
  "optimo_hasta": 16.0
 },
 {
  "id": "91bb2f4e-ab52-1800-f66a-fdedf4ab02f5",
  "clave": "pausa_cada_30",
  "nombre": "Pausa activa cada 30 minutos",
  "categoria": {
   "id": "ed1867f2-83b3-45a9-b27e-4f650f36c275",
   "clave": "ejercicio",
   "nombre": "Ejercicio",
   "color": "#D9480F",
   "icono": "fitness_center"
  },
  "subcategoria": {
   "id": "c91f57b0-2064-42c6-a390-ff9f23fbe86d",
   "clave": "pausas_activas",
   "nombre": "Pausas activas",
   "icono": "timer",
   "sentido": "aumentar"
  },
  "unidad": "pausas",
  "meta": 16.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 31,
   "veces_semana": null
  },
  "momento": "Con una alarma cada 30 minutos",
  "porque": "Interrumpir el tiempo sentado cada 20 a 30 minutos dio los mejores resultados en los estudios.",
  "fuentes": "F17",
  "zona": "optimo",
  "optimo_desde": 8.0,
  "optimo_hasta": 16.0
 },
 {
  "id": "59701508-0237-6847-b734-771016de93a8",
  "clave": "pausas_estudio",
  "nombre": "Pausas al estudiar o trabajar",
  "categoria": {
   "id": "ed1867f2-83b3-45a9-b27e-4f650f36c275",
   "clave": "ejercicio",
   "nombre": "Ejercicio",
   "color": "#D9480F",
   "icono": "fitness_center"
  },
  "subcategoria": {
   "id": "c91f57b0-2064-42c6-a390-ff9f23fbe86d",
   "clave": "pausas_activas",
   "nombre": "Pausas activas",
   "icono": "timer",
   "sentido": "aumentar"
  },
  "unidad": "pausas",
  "meta": 10.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Al terminar cada bloque de trabajo",
  "porque": "Romper el tiempo sentado con pausas cortas reduce los efectos de estar quieto mucho tiempo.",
  "fuentes": "F11, F17",
  "zona": "optimo",
  "optimo_desde": 8.0,
  "optimo_hasta": 16.0
 },
 {
  "id": "2fe1f043-7896-141f-41df-aff1ffb00ebd",
  "clave": "agua_8_vasos",
  "nombre": "Tomar 8 vasos de agua",
  "categoria": {
   "id": "0fe8d75e-c905-4c62-9b92-2530603daa11",
   "clave": "salud",
   "nombre": "Salud",
   "color": "#3F7D20",
   "icono": "favorite"
  },
  "subcategoria": {
   "id": "a5a74ba6-ff76-49fc-8870-20fbed95a3b0",
   "clave": "hidratacion",
   "nombre": "Hidratación",
   "icono": "water_drop",
   "sentido": "aumentar"
  },
  "unidad": "vasos",
  "meta": 8.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Con cada comida y entre comidas",
  "porque": "De bebidas se recomiendan entre 1.5 y 3 litros al día: 8 vasos son 2 litros.",
  "fuentes": "F20, F21",
  "zona": "optimo",
  "optimo_desde": 6.0,
  "optimo_hasta": 12.0
 },
 {
  "id": "b26c8f94-4cd7-4605-d487-ff3f5eda2dc9",
  "clave": "agua_2_litros",
  "nombre": "Tomar 2 litros de agua",
  "categoria": {
   "id": "0fe8d75e-c905-4c62-9b92-2530603daa11",
   "clave": "salud",
   "nombre": "Salud",
   "color": "#3F7D20",
   "icono": "favorite"
  },
  "subcategoria": {
   "id": "a5a74ba6-ff76-49fc-8870-20fbed95a3b0",
   "clave": "hidratacion",
   "nombre": "Hidratación",
   "icono": "water_drop",
   "sentido": "aumentar"
  },
  "unidad": "L",
  "meta": 2.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Con una botella siempre a la mano",
  "porque": "Dos litros de bebidas al día están en el centro de lo recomendado (de 1.5 a 3 litros).",
  "fuentes": "F20, F21",
  "zona": "optimo",
  "optimo_desde": 1.5,
  "optimo_hasta": 3.0
 },
 {
  "id": "2ac92cfc-8148-0323-bf42-23e9a0c03e20",
  "clave": "agua_1_5_litros",
  "nombre": "Tomar 1.5 litros de agua",
  "categoria": {
   "id": "0fe8d75e-c905-4c62-9b92-2530603daa11",
   "clave": "salud",
   "nombre": "Salud",
   "color": "#3F7D20",
   "icono": "favorite"
  },
  "subcategoria": {
   "id": "a5a74ba6-ff76-49fc-8870-20fbed95a3b0",
   "clave": "hidratacion",
   "nombre": "Hidratación",
   "icono": "water_drop",
   "sentido": "aumentar"
  },
  "unidad": "L",
  "meta": 1.5,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Al despertar y con cada comida",
  "porque": "Litro y medio de bebidas al día es el mínimo recomendado.",
  "fuentes": "F20",
  "zona": "optimo",
  "optimo_desde": 1.5,
  "optimo_hasta": 3.0
 },
 {
  "id": "709a080c-31d8-629f-fec9-45aabef011d2",
  "clave": "agua_2500_ml",
  "nombre": "Tomar 2,500 ml de agua",
  "categoria": {
   "id": "0fe8d75e-c905-4c62-9b92-2530603daa11",
   "clave": "salud",
   "nombre": "Salud",
   "color": "#3F7D20",
   "icono": "favorite"
  },
  "subcategoria": {
   "id": "a5a74ba6-ff76-49fc-8870-20fbed95a3b0",
   "clave": "hidratacion",
   "nombre": "Hidratación",
   "icono": "water_drop",
   "sentido": "aumentar"
  },
  "unidad": "ml",
  "meta": 2500.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "En días de calor o de ejercicio",
  "porque": "Con calor o ejercicio conviene ir hacia lo alto del rango, sin pasar de 3 litros de bebidas al día.",
  "fuentes": "F20, F21",
  "zona": "optimo",
  "optimo_desde": 1500.0,
  "optimo_hasta": 3000.0
 },
 {
  "id": "e92ae952-c024-3191-48a9-5b07fe77f7ee",
  "clave": "dormir_7",
  "nombre": "Dormir 7 horas",
  "categoria": {
   "id": "0fe8d75e-c905-4c62-9b92-2530603daa11",
   "clave": "salud",
   "nombre": "Salud",
   "color": "#3F7D20",
   "icono": "favorite"
  },
  "subcategoria": {
   "id": "a30f00ea-dca5-45c9-93fb-0a32bdb5d92f",
   "clave": "sueno",
   "nombre": "Sueño",
   "icono": "bedtime",
   "sentido": "aumentar"
  },
  "unidad": "h",
  "meta": 7.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "A la misma hora cada noche",
  "porque": "Los adultos necesitan dormir al menos 7 horas por noche.",
  "fuentes": "F18",
  "zona": "optimo",
  "optimo_desde": 7.0,
  "optimo_hasta": 9.0
 },
 {
  "id": "f1670b00-81c6-ae05-919b-35052f9b499a",
  "clave": "dormir_8",
  "nombre": "Dormir 8 horas",
  "categoria": {
   "id": "0fe8d75e-c905-4c62-9b92-2530603daa11",
   "clave": "salud",
   "nombre": "Salud",
   "color": "#3F7D20",
   "icono": "favorite"
  },
  "subcategoria": {
   "id": "a30f00ea-dca5-45c9-93fb-0a32bdb5d92f",
   "clave": "sueno",
   "nombre": "Sueño",
   "icono": "bedtime",
   "sentido": "aumentar"
  },
  "unidad": "h",
  "meta": 8.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Después de apagar las pantallas",
  "porque": "Entre 7 y 9 horas por noche es lo recomendado para adultos.",
  "fuentes": "F18, F19",
  "zona": "optimo",
  "optimo_desde": 7.0,
  "optimo_hasta": 9.0
 },
 {
  "id": "a279ae5b-f4d9-2399-1f38-18b71b538c38",
  "clave": "dormir_7_5",
  "nombre": "Dormir 7.5 horas",
  "categoria": {
   "id": "0fe8d75e-c905-4c62-9b92-2530603daa11",
   "clave": "salud",
   "nombre": "Salud",
   "color": "#3F7D20",
   "icono": "favorite"
  },
  "subcategoria": {
   "id": "a30f00ea-dca5-45c9-93fb-0a32bdb5d92f",
   "clave": "sueno",
   "nombre": "Sueño",
   "icono": "bedtime",
   "sentido": "aumentar"
  },
  "unidad": "h",
  "meta": 7.5,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Acostándote a la misma hora, también el fin de semana",
  "porque": "Un horario regular ayuda a dormir lo recomendado: de 7 a 9 horas.",
  "fuentes": "F18, F19",
  "zona": "optimo",
  "optimo_desde": 7.0,
  "optimo_hasta": 9.0
 },
 {
  "id": "1bb427e9-be8a-3544-51a6-134ae92ea34b",
  "clave": "dormir_8_5",
  "nombre": "Dormir 8.5 horas",
  "categoria": {
   "id": "0fe8d75e-c905-4c62-9b92-2530603daa11",
   "clave": "salud",
   "nombre": "Salud",
   "color": "#3F7D20",
   "icono": "favorite"
  },
  "subcategoria": {
   "id": "a30f00ea-dca5-45c9-93fb-0a32bdb5d92f",
   "clave": "sueno",
   "nombre": "Sueño",
   "icono": "bedtime",
   "sentido": "aumentar"
  },
  "unidad": "h",
  "meta": 8.5,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Si sueles despertar cansado",
  "porque": "Si despiertas cansado, acercarte a 9 horas sigue dentro de lo recomendado.",
  "fuentes": "F19",
  "zona": "optimo",
  "optimo_desde": 7.0,
  "optimo_hasta": 9.0
 },
 {
  "id": "efcec5df-77ac-04d9-cd27-b9909c6ad0da",
  "clave": "frutas_5",
  "nombre": "Comer 5 porciones de frutas y verduras",
  "categoria": {
   "id": "0fe8d75e-c905-4c62-9b92-2530603daa11",
   "clave": "salud",
   "nombre": "Salud",
   "color": "#3F7D20",
   "icono": "favorite"
  },
  "subcategoria": {
   "id": "04ad3096-c1f8-4dc5-a20d-57b114be4b58",
   "clave": "frutas_verduras",
   "nombre": "Frutas y verduras",
   "icono": "eco",
   "sentido": "aumentar"
  },
  "unidad": "porciones",
  "meta": 5.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "En cada comida",
  "porque": "Se recomiendan al menos 400 g al día: 5 porciones de 80 g.",
  "fuentes": "F23",
  "zona": "optimo",
  "optimo_desde": 5.0,
  "optimo_hasta": 10.0
 },
 {
  "id": "37c5e7f9-0129-a04c-cfcb-8fe83871498d",
  "clave": "frutas_400g",
  "nombre": "Comer 400 g de frutas y verduras",
  "categoria": {
   "id": "0fe8d75e-c905-4c62-9b92-2530603daa11",
   "clave": "salud",
   "nombre": "Salud",
   "color": "#3F7D20",
   "icono": "favorite"
  },
  "subcategoria": {
   "id": "04ad3096-c1f8-4dc5-a20d-57b114be4b58",
   "clave": "frutas_verduras",
   "nombre": "Frutas y verduras",
   "icono": "eco",
   "sentido": "aumentar"
  },
  "unidad": "g",
  "meta": 400.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Midiendo tus porciones al servir",
  "porque": "Al menos 400 g de frutas y verduras al día es lo mínimo recomendado.",
  "fuentes": "F23",
  "zona": "optimo",
  "optimo_desde": 400.0,
  "optimo_hasta": 800.0
 },
 {
  "id": "ec0d17a3-f6af-8b41-ade3-f3313e3b5d2c",
  "clave": "frutas_7",
  "nombre": "Comer 7 porciones de frutas y verduras",
  "categoria": {
   "id": "0fe8d75e-c905-4c62-9b92-2530603daa11",
   "clave": "salud",
   "nombre": "Salud",
   "color": "#3F7D20",
   "icono": "favorite"
  },
  "subcategoria": {
   "id": "04ad3096-c1f8-4dc5-a20d-57b114be4b58",
   "clave": "frutas_verduras",
   "nombre": "Frutas y verduras",
   "icono": "eco",
   "sentido": "aumentar"
  },
  "unidad": "porciones",
  "meta": 7.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Agregando verdura a la comida y a la cena",
  "porque": "El beneficio sigue aumentando hasta unos 800 g al día (10 porciones).",
  "fuentes": "F23, F24",
  "zona": "optimo",
  "optimo_desde": 5.0,
  "optimo_hasta": 10.0
 },
 {
  "id": "f12e84f3-12b7-bf1e-5634-325d1cc8c9db",
  "clave": "verdura_cada_comida",
  "nombre": "Verdura en cada comida",
  "categoria": {
   "id": "0fe8d75e-c905-4c62-9b92-2530603daa11",
   "clave": "salud",
   "nombre": "Salud",
   "color": "#3F7D20",
   "icono": "favorite"
  },
  "subcategoria": {
   "id": "04ad3096-c1f8-4dc5-a20d-57b114be4b58",
   "clave": "frutas_verduras",
   "nombre": "Frutas y verduras",
   "icono": "eco",
   "sentido": "aumentar"
  },
  "unidad": "porciones",
  "meta": 6.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Al servir tu plato",
  "porque": "Llenar parte del plato con verdura ayuda a llegar a 5 porciones o más al día.",
  "fuentes": "F23, F24",
  "zona": "optimo",
  "optimo_desde": 5.0,
  "optimo_hasta": 10.0
 },
 {
  "id": "b47ba601-6043-22cb-03da-6079e5b67b91",
  "clave": "azucar_25g",
  "nombre": "Limitar el azúcar a 25 g",
  "categoria": {
   "id": "0fe8d75e-c905-4c62-9b92-2530603daa11",
   "clave": "salud",
   "nombre": "Salud",
   "color": "#3F7D20",
   "icono": "favorite"
  },
  "subcategoria": {
   "id": "6bd22c97-bf54-49de-a3c3-d03b9f6bf55a",
   "clave": "reducir_azucar",
   "nombre": "Reducir azúcar",
   "icono": "cookie",
   "sentido": "reducir"
  },
  "unidad": "g",
  "meta": 25.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Al elegir bebidas y postres",
  "porque": "Lo ideal es menos de 25 g de azúcar libre al día, y nunca más de 50 g.",
  "fuentes": "F23",
  "zona": "optimo",
  "optimo_desde": 0.0,
  "optimo_hasta": 25.0
 },
 {
  "id": "c640e466-d16f-3e3c-5deb-230f1bf00382",
  "clave": "azucar_6_cucharaditas",
  "nombre": "Máximo 6 cucharaditas de azúcar",
  "categoria": {
   "id": "0fe8d75e-c905-4c62-9b92-2530603daa11",
   "clave": "salud",
   "nombre": "Salud",
   "color": "#3F7D20",
   "icono": "favorite"
  },
  "subcategoria": {
   "id": "6bd22c97-bf54-49de-a3c3-d03b9f6bf55a",
   "clave": "reducir_azucar",
   "nombre": "Reducir azúcar",
   "icono": "cookie",
   "sentido": "reducir"
  },
  "unidad": "cucharaditas",
  "meta": 6.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Al endulzar café o té",
  "porque": "Seis cucharaditas son unos 24 g: debajo del ideal de 25 g de azúcar libre al día.",
  "fuentes": "F23",
  "zona": "optimo",
  "optimo_desde": 0.0,
  "optimo_hasta": 6.25
 },
 {
  "id": "ca0940da-3533-663c-6a6f-e0a519d2b687",
  "clave": "sin_refrescos",
  "nombre": "Cambiar el refresco por agua",
  "categoria": {
   "id": "0fe8d75e-c905-4c62-9b92-2530603daa11",
   "clave": "salud",
   "nombre": "Salud",
   "color": "#3F7D20",
   "icono": "favorite"
  },
  "subcategoria": {
   "id": "6bd22c97-bf54-49de-a3c3-d03b9f6bf55a",
   "clave": "reducir_azucar",
   "nombre": "Reducir azúcar",
   "icono": "cookie",
   "sentido": "reducir"
  },
  "unidad": "g",
  "meta": 15.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "En cada comida, con agua natural",
  "porque": "Las bebidas azucaradas son de las principales fuentes de azúcar libre; dejarlas te ayuda a quedarte debajo de 25 g.",
  "fuentes": "F23",
  "zona": "optimo",
  "optimo_desde": 0.0,
  "optimo_hasta": 25.0
 },
 {
  "id": "b5983b67-d9c3-5d8b-13c3-5f59de12b302",
  "clave": "alcohol_2",
  "nombre": "Máximo 2 bebidas alcohólicas a la semana",
  "categoria": {
   "id": "0fe8d75e-c905-4c62-9b92-2530603daa11",
   "clave": "salud",
   "nombre": "Salud",
   "color": "#3F7D20",
   "icono": "favorite"
  },
  "subcategoria": {
   "id": "6243db2e-c2be-4c3d-b092-58a4f9b901b8",
   "clave": "reducir_alcohol",
   "nombre": "Reducir alcohol",
   "icono": "no_drinks",
   "sentido": "reducir"
  },
  "unidad": "bebidas",
  "meta": 2.0,
  "frecuencia": {
   "tipo": "n_por_semana",
   "dias_semana": null,
   "veces_semana": 1
  },
  "momento": "El fin de semana, contando cada bebida",
  "porque": "Ningún nivel de alcohol es seguro; de 1 a 2 bebidas a la semana es riesgo bajo.",
  "fuentes": "F25, F26",
  "zona": "optimo",
  "optimo_desde": 0.0,
  "optimo_hasta": 2.0
 },
 {
  "id": "734160b1-e989-e8d0-ccc7-0c721b94683e",
  "clave": "alcohol_1",
  "nombre": "Máximo 1 bebida alcohólica a la semana",
  "categoria": {
   "id": "0fe8d75e-c905-4c62-9b92-2530603daa11",
   "clave": "salud",
   "nombre": "Salud",
   "color": "#3F7D20",
   "icono": "favorite"
  },
  "subcategoria": {
   "id": "6243db2e-c2be-4c3d-b092-58a4f9b901b8",
   "clave": "reducir_alcohol",
   "nombre": "Reducir alcohol",
   "icono": "no_drinks",
   "sentido": "reducir"
  },
  "unidad": "bebidas",
  "meta": 1.0,
  "frecuencia": {
   "tipo": "n_por_semana",
   "dias_semana": null,
   "veces_semana": 1
  },
  "momento": "En reuniones, alternando con agua",
  "porque": "Entre menos alcohol, mejor: una bebida a la semana mantiene el riesgo bajo.",
  "fuentes": "F25, F26",
  "zona": "optimo",
  "optimo_desde": 0.0,
  "optimo_hasta": 2.0
 },
 {
  "id": "b53bf93c-1f1c-6898-f815-bebf3f997476",
  "clave": "alcohol_solo_sabado",
  "nombre": "Una bebida como máximo, solo el sábado",
  "categoria": {
   "id": "0fe8d75e-c905-4c62-9b92-2530603daa11",
   "clave": "salud",
   "nombre": "Salud",
   "color": "#3F7D20",
   "icono": "favorite"
  },
  "subcategoria": {
   "id": "6243db2e-c2be-4c3d-b092-58a4f9b901b8",
   "clave": "reducir_alcohol",
   "nombre": "Reducir alcohol",
   "icono": "no_drinks",
   "sentido": "reducir"
  },
  "unidad": "bebidas",
  "meta": 1.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 32,
   "veces_semana": null
  },
  "momento": "Si sales el sábado",
  "porque": "Ningún nivel es seguro: ponerte un tope claro te ayuda a no pasar de 2 bebidas a la semana.",
  "fuentes": "F25, F26",
  "zona": "optimo",
  "optimo_desde": 0.0,
  "optimo_hasta": 2.0
 },
 {
  "id": "7a7d8e85-21fe-a8ce-1369-3ec2446f7985",
  "clave": "fumar_5",
  "nombre": "Bajar a 5 cigarros al día",
  "categoria": {
   "id": "0fe8d75e-c905-4c62-9b92-2530603daa11",
   "clave": "salud",
   "nombre": "Salud",
   "color": "#3F7D20",
   "icono": "favorite"
  },
  "subcategoria": {
   "id": "8327cc28-f178-44b7-b66c-c4ae4cb79f23",
   "clave": "dejar_fumar",
   "nombre": "Dejar de fumar",
   "icono": "smoke_free",
   "sentido": "reducir"
  },
  "unidad": "cigarros",
  "meta": 5.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Retrasando el primero de la mañana",
  "porque": "No hay un nivel seguro: un cigarro al día conserva buena parte del riesgo. La Escalera te ayuda a bajar poco a poco hasta dejarlo.",
  "fuentes": "F27",
  "zona": "alto",
  "optimo_desde": 0.0,
  "optimo_hasta": 0.0
 },
 {
  "id": "3bb2f3fb-a058-245d-2386-0f69c09a22f4",
  "clave": "fumar_1",
  "nombre": "Bajar a 1 cigarro al día",
  "categoria": {
   "id": "0fe8d75e-c905-4c62-9b92-2530603daa11",
   "clave": "salud",
   "nombre": "Salud",
   "color": "#3F7D20",
   "icono": "favorite"
  },
  "subcategoria": {
   "id": "8327cc28-f178-44b7-b66c-c4ae4cb79f23",
   "clave": "dejar_fumar",
   "nombre": "Dejar de fumar",
   "icono": "smoke_free",
   "sentido": "reducir"
  },
  "unidad": "cigarros",
  "meta": 1.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Solo después de comer",
  "porque": "Bajar a uno es un gran paso, pero no hay nivel seguro: el siguiente es dejarlo.",
  "fuentes": "F27",
  "zona": "alto",
  "optimo_desde": 0.0,
  "optimo_hasta": 0.0
 },
 {
  "id": "51f43a26-6a88-71f6-9e2f-74416461b3d6",
  "clave": "leer_30",
  "nombre": "Leer 30 minutos",
  "categoria": {
   "id": "a7caa85f-4896-4484-9ea5-b648cc42c683",
   "clave": "educacion",
   "nombre": "Educación",
   "color": "#2563EB",
   "icono": "school"
  },
  "subcategoria": {
   "id": "3bdc6868-b2df-4efe-bd11-60508d2a3d85",
   "clave": "lectura",
   "nombre": "Lectura",
   "icono": "menu_book",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 30.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Antes de dormir",
  "porque": "Leer al menos 3.5 horas a la semana (30 minutos al día) se asoció con vivir más años.",
  "fuentes": "F28",
  "zona": "optimo",
  "optimo_desde": 30.0,
  "optimo_hasta": 60.0
 },
 {
  "id": "8da22599-d1ff-2ed8-1b34-854acecbd304",
  "clave": "leer_45",
  "nombre": "Leer 45 minutos",
  "categoria": {
   "id": "a7caa85f-4896-4484-9ea5-b648cc42c683",
   "clave": "educacion",
   "nombre": "Educación",
   "color": "#2563EB",
   "icono": "school"
  },
  "subcategoria": {
   "id": "3bdc6868-b2df-4efe-bd11-60508d2a3d85",
   "clave": "lectura",
   "nombre": "Lectura",
   "icono": "menu_book",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 45.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Durante tus traslados",
  "porque": "Entre 30 y 60 minutos al día está dentro de lo recomendado.",
  "fuentes": "F28",
  "zona": "optimo",
  "optimo_desde": 30.0,
  "optimo_hasta": 60.0
 },
 {
  "id": "d6871fb9-a1a7-643d-0bf3-52dfb6dd7d6c",
  "clave": "leer_60",
  "nombre": "Leer una hora",
  "categoria": {
   "id": "a7caa85f-4896-4484-9ea5-b648cc42c683",
   "clave": "educacion",
   "nombre": "Educación",
   "color": "#2563EB",
   "icono": "school"
  },
  "subcategoria": {
   "id": "3bdc6868-b2df-4efe-bd11-60508d2a3d85",
   "clave": "lectura",
   "nombre": "Lectura",
   "icono": "menu_book",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 60.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Después de cenar",
  "porque": "Hasta una hora al día sigue dentro de lo recomendado; leer más no hace daño.",
  "fuentes": "F28",
  "zona": "optimo",
  "optimo_desde": 30.0,
  "optimo_hasta": 60.0
 },
 {
  "id": "80c241b8-c145-aad9-6592-93bec67173bc",
  "clave": "leer_24_paginas",
  "nombre": "Leer 24 páginas",
  "categoria": {
   "id": "a7caa85f-4896-4484-9ea5-b648cc42c683",
   "clave": "educacion",
   "nombre": "Educación",
   "color": "#2563EB",
   "icono": "school"
  },
  "subcategoria": {
   "id": "3bdc6868-b2df-4efe-bd11-60508d2a3d85",
   "clave": "lectura",
   "nombre": "Lectura",
   "icono": "menu_book",
   "sentido": "aumentar"
  },
  "unidad": "páginas",
  "meta": 24.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Antes de dormir",
  "porque": "24 páginas al día equivalen a unos 30 minutos de lectura.",
  "fuentes": "F28, F29",
  "zona": "optimo",
  "optimo_desde": 24.0,
  "optimo_hasta": 48.0
 },
 {
  "id": "2c67b35c-f419-8e95-ebd6-9270a8310ed8",
  "clave": "leer_30_paginas",
  "nombre": "Leer 30 páginas",
  "categoria": {
   "id": "a7caa85f-4896-4484-9ea5-b648cc42c683",
   "clave": "educacion",
   "nombre": "Educación",
   "color": "#2563EB",
   "icono": "school"
  },
  "subcategoria": {
   "id": "3bdc6868-b2df-4efe-bd11-60508d2a3d85",
   "clave": "lectura",
   "nombre": "Lectura",
   "icono": "menu_book",
   "sentido": "aumentar"
  },
  "unidad": "páginas",
  "meta": 30.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Después de desayunar",
  "porque": "30 páginas al día son unos 37 minutos de lectura, dentro de lo recomendado.",
  "fuentes": "F28, F29",
  "zona": "optimo",
  "optimo_desde": 24.0,
  "optimo_hasta": 48.0
 },
 {
  "id": "5304b1e1-9c1b-2057-603b-5f8e0fe4308a",
  "clave": "lectura_fin_semana",
  "nombre": "Lectura larga de fin de semana",
  "categoria": {
   "id": "a7caa85f-4896-4484-9ea5-b648cc42c683",
   "clave": "educacion",
   "nombre": "Educación",
   "color": "#2563EB",
   "icono": "school"
  },
  "subcategoria": {
   "id": "3bdc6868-b2df-4efe-bd11-60508d2a3d85",
   "clave": "lectura",
   "nombre": "Lectura",
   "icono": "menu_book",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 105.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 96,
   "veces_semana": null
  },
  "momento": "Sábado y domingo por la mañana",
  "porque": "Puedes llegar a las 3.5 horas semanales en dos sesiones largas.",
  "fuentes": "F28",
  "zona": "optimo",
  "optimo_desde": 105.0,
  "optimo_hasta": 210.0
 },
 {
  "id": "92902f79-cfe2-a4cd-46d4-b6150dda3b15",
  "clave": "leer_entre_semana",
  "nombre": "Leer 45 minutos entre semana",
  "categoria": {
   "id": "a7caa85f-4896-4484-9ea5-b648cc42c683",
   "clave": "educacion",
   "nombre": "Educación",
   "color": "#2563EB",
   "icono": "school"
  },
  "subcategoria": {
   "id": "3bdc6868-b2df-4efe-bd11-60508d2a3d85",
   "clave": "lectura",
   "nombre": "Lectura",
   "icono": "menu_book",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 45.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 31,
   "veces_semana": null
  },
  "momento": "Al llegar a casa",
  "porque": "45 minutos de lunes a viernes suman 225 a la semana, dentro de lo recomendado.",
  "fuentes": "F28",
  "zona": "optimo",
  "optimo_desde": 42.0,
  "optimo_hasta": 84.0
 },
 {
  "id": "819f32e1-4fbb-1a92-b65b-dca5eb778e94",
  "clave": "estudiar_bloques",
  "nombre": "Estudiar en bloques",
  "categoria": {
   "id": "a7caa85f-4896-4484-9ea5-b648cc42c683",
   "clave": "educacion",
   "nombre": "Educación",
   "color": "#2563EB",
   "icono": "school"
  },
  "subcategoria": {
   "id": "beef97ba-c3de-49ba-98b0-d116ee92e284",
   "clave": "estudio",
   "nombre": "Estudio",
   "icono": "edit_note",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 60.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 31,
   "veces_semana": null
  },
  "momento": "Después de comer, en bloques de 25 minutos con pausas",
  "porque": "Repartir el estudio en varias sesiones rinde más que estudiar todo de corrido.",
  "fuentes": "F30",
  "zona": "optimo",
  "optimo_desde": 30.0,
  "optimo_hasta": 180.0
 },
 {
  "id": "dc06afa8-5832-114c-b834-2aeb31b60949",
  "clave": "repasar",
  "nombre": "Repasar lo aprendido",
  "categoria": {
   "id": "a7caa85f-4896-4484-9ea5-b648cc42c683",
   "clave": "educacion",
   "nombre": "Educación",
   "color": "#2563EB",
   "icono": "school"
  },
  "subcategoria": {
   "id": "beef97ba-c3de-49ba-98b0-d116ee92e284",
   "clave": "estudio",
   "nombre": "Estudio",
   "icono": "edit_note",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 30.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 21,
   "veces_semana": null
  },
  "momento": "Al día siguiente de cada clase",
  "porque": "Repasar en días distintos fija mejor lo aprendido que repasarlo todo de una vez.",
  "fuentes": "F30",
  "zona": "optimo",
  "optimo_desde": 30.0,
  "optimo_hasta": 180.0
 },
 {
  "id": "74e5fab6-d8ea-cef3-9816-0711eb7bf35f",
  "clave": "estudiar_2h",
  "nombre": "Estudiar 2 horas",
  "categoria": {
   "id": "a7caa85f-4896-4484-9ea5-b648cc42c683",
   "clave": "educacion",
   "nombre": "Educación",
   "color": "#2563EB",
   "icono": "school"
  },
  "subcategoria": {
   "id": "beef97ba-c3de-49ba-98b0-d116ee92e284",
   "clave": "estudio",
   "nombre": "Estudio",
   "icono": "edit_note",
   "sentido": "aumentar"
  },
  "unidad": "h",
  "meta": 2.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 31,
   "veces_semana": null
  },
  "momento": "En tu horario de mayor concentración",
  "porque": "Hasta unas 4 horas al día de práctica concentrada se pueden sostener; 2 horas dejan margen para descansar.",
  "fuentes": "F31",
  "zona": "optimo",
  "optimo_desde": 0.5,
  "optimo_hasta": 3.0
 },
 {
  "id": "d500ff2e-73e1-7d9e-1f29-ce9d6799b526",
  "clave": "estudiar_lugar_fijo",
  "nombre": "Estudiar 90 minutos en un lugar fijo",
  "categoria": {
   "id": "a7caa85f-4896-4484-9ea5-b648cc42c683",
   "clave": "educacion",
   "nombre": "Educación",
   "color": "#2563EB",
   "icono": "school"
  },
  "subcategoria": {
   "id": "beef97ba-c3de-49ba-98b0-d116ee92e284",
   "clave": "estudio",
   "nombre": "Estudio",
   "icono": "edit_note",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 90.0,
  "frecuencia": {
   "tipo": "n_por_semana",
   "dias_semana": null,
   "veces_semana": 4
  },
  "momento": "En la biblioteca o en tu escritorio",
  "porque": "Estudiar siempre en el mismo lugar ayuda a que el contexto dispare el hábito.",
  "fuentes": "F03, F30",
  "zona": "optimo",
  "optimo_desde": 30.0,
  "optimo_hasta": 180.0
 },
 {
  "id": "5b648459-1f05-67b1-e9a2-d59b8bead9a8",
  "clave": "ejercicios_practica",
  "nombre": "Resolver ejercicios de práctica",
  "categoria": {
   "id": "a7caa85f-4896-4484-9ea5-b648cc42c683",
   "clave": "educacion",
   "nombre": "Educación",
   "color": "#2563EB",
   "icono": "school"
  },
  "subcategoria": {
   "id": "beef97ba-c3de-49ba-98b0-d116ee92e284",
   "clave": "estudio",
   "nombre": "Estudio",
   "icono": "edit_note",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 45.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 42,
   "veces_semana": null
  },
  "momento": "Después de clase",
  "porque": "Practicar en días separados fija mejor lo aprendido que hacerlo todo junto.",
  "fuentes": "F30",
  "zona": "optimo",
  "optimo_desde": 30.0,
  "optimo_hasta": 180.0
 },
 {
  "id": "159c3d6d-d6d8-ef5f-3e8e-c2ae614a7a1a",
  "clave": "preparar_examenes",
  "nombre": "Preparar exámenes con anticipación",
  "categoria": {
   "id": "a7caa85f-4896-4484-9ea5-b648cc42c683",
   "clave": "educacion",
   "nombre": "Educación",
   "color": "#2563EB",
   "icono": "school"
  },
  "subcategoria": {
   "id": "beef97ba-c3de-49ba-98b0-d116ee92e284",
   "clave": "estudio",
   "nombre": "Estudio",
   "icono": "edit_note",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 40.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Desde dos semanas antes del examen",
  "porque": "Estudiar un poco cada día durante varias semanas rinde más que estudiar todo la noche anterior.",
  "fuentes": "F30",
  "zona": "optimo",
  "optimo_desde": 30.0,
  "optimo_hasta": 180.0
 },
 {
  "id": "d49cb2e6-aa52-5f74-5cfe-19159fbb46a1",
  "clave": "practica_deliberada",
  "nombre": "Práctica deliberada de una habilidad",
  "categoria": {
   "id": "a7caa85f-4896-4484-9ea5-b648cc42c683",
   "clave": "educacion",
   "nombre": "Educación",
   "color": "#2563EB",
   "icono": "school"
  },
  "subcategoria": {
   "id": "beef97ba-c3de-49ba-98b0-d116ee92e284",
   "clave": "estudio",
   "nombre": "Estudio",
   "icono": "edit_note",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 60.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 31,
   "veces_semana": null
  },
  "momento": "A la misma hora cada día",
  "porque": "La práctica concentrada y sostenida es lo que más mejora una habilidad; el máximo sostenible ronda 4 horas al día.",
  "fuentes": "F31",
  "zona": "optimo",
  "optimo_desde": 30.0,
  "optimo_hasta": 180.0
 },
 {
  "id": "b5dafa72-1db1-219a-398a-b679ebb2bab3",
  "clave": "idioma_15",
  "nombre": "Practicar un idioma 15 minutos",
  "categoria": {
   "id": "a7caa85f-4896-4484-9ea5-b648cc42c683",
   "clave": "educacion",
   "nombre": "Educación",
   "color": "#2563EB",
   "icono": "school"
  },
  "subcategoria": {
   "id": "19ed515c-78b4-4b8f-8fd0-e3720243d043",
   "clave": "idiomas",
   "nombre": "Idiomas",
   "icono": "translate",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 15.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Después de desayunar",
  "porque": "Practicar poco y seguido aprovecha la práctica espaciada.",
  "fuentes": "F30",
  "zona": "optimo",
  "optimo_desde": 15.0,
  "optimo_hasta": 60.0
 },
 {
  "id": "3b93a75c-db11-dff0-9c23-4f4d3251638b",
  "clave": "idioma_30",
  "nombre": "Practicar un idioma 30 minutos",
  "categoria": {
   "id": "a7caa85f-4896-4484-9ea5-b648cc42c683",
   "clave": "educacion",
   "nombre": "Educación",
   "color": "#2563EB",
   "icono": "school"
  },
  "subcategoria": {
   "id": "19ed515c-78b4-4b8f-8fd0-e3720243d043",
   "clave": "idiomas",
   "nombre": "Idiomas",
   "icono": "translate",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 30.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 31,
   "veces_semana": null
  },
  "momento": "En tus traslados",
  "porque": "Sesiones de 15 a 60 minutos, repartidas en la semana, aprovechan la práctica espaciada.",
  "fuentes": "F30",
  "zona": "optimo",
  "optimo_desde": 15.0,
  "optimo_hasta": 60.0
 },
 {
  "id": "7944b377-04ff-2601-b2d8-410e898c0ac7",
  "clave": "repasar_vocabulario",
  "nombre": "Repasar vocabulario",
  "categoria": {
   "id": "a7caa85f-4896-4484-9ea5-b648cc42c683",
   "clave": "educacion",
   "nombre": "Educación",
   "color": "#2563EB",
   "icono": "school"
  },
  "subcategoria": {
   "id": "19ed515c-78b4-4b8f-8fd0-e3720243d043",
   "clave": "idiomas",
   "nombre": "Idiomas",
   "icono": "translate",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 15.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Antes de dormir",
  "porque": "Repasar las palabras en días distintos las fija mejor que estudiarlas de una vez.",
  "fuentes": "F30",
  "zona": "optimo",
  "optimo_desde": 15.0,
  "optimo_hasta": 60.0
 },
 {
  "id": "2e795c62-4f12-1df8-cc66-80b6958be349",
  "clave": "conversar_idioma",
  "nombre": "Conversar en otro idioma",
  "categoria": {
   "id": "a7caa85f-4896-4484-9ea5-b648cc42c683",
   "clave": "educacion",
   "nombre": "Educación",
   "color": "#2563EB",
   "icono": "school"
  },
  "subcategoria": {
   "id": "19ed515c-78b4-4b8f-8fd0-e3720243d043",
   "clave": "idiomas",
   "nombre": "Idiomas",
   "icono": "translate",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 30.0,
  "frecuencia": {
   "tipo": "n_por_semana",
   "dias_semana": null,
   "veces_semana": 2
  },
  "momento": "Con un compañero o un grupo",
  "porque": "Practicar hablando en sesiones espaciadas complementa el estudio diario.",
  "fuentes": "F30",
  "zona": "optimo",
  "optimo_desde": 15.0,
  "optimo_hasta": 60.0
 },
 {
  "id": "f8398051-8901-9da6-2456-693338447b5f",
  "clave": "escuchar_idioma",
  "nombre": "Escuchar contenido en otro idioma",
  "categoria": {
   "id": "a7caa85f-4896-4484-9ea5-b648cc42c683",
   "clave": "educacion",
   "nombre": "Educación",
   "color": "#2563EB",
   "icono": "school"
  },
  "subcategoria": {
   "id": "19ed515c-78b4-4b8f-8fd0-e3720243d043",
   "clave": "idiomas",
   "nombre": "Idiomas",
   "icono": "translate",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 20.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Mientras caminas o haces quehaceres",
  "porque": "Exponerte un poco cada día aprovecha la práctica espaciada.",
  "fuentes": "F30",
  "zona": "optimo",
  "optimo_desde": 15.0,
  "optimo_hasta": 60.0
 },
 {
  "id": "1e07e4b0-7ee7-fc5e-7260-eab9d43cdc33",
  "clave": "clase_idioma",
  "nombre": "Clase o lección de idioma",
  "categoria": {
   "id": "a7caa85f-4896-4484-9ea5-b648cc42c683",
   "clave": "educacion",
   "nombre": "Educación",
   "color": "#2563EB",
   "icono": "school"
  },
  "subcategoria": {
   "id": "19ed515c-78b4-4b8f-8fd0-e3720243d043",
   "clave": "idiomas",
   "nombre": "Idiomas",
   "icono": "translate",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 45.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 21,
   "veces_semana": null
  },
  "momento": "A la misma hora, tres veces por semana",
  "porque": "Un horario fijo ayuda a que el hábito se dispare solo, y repartir las clases rinde más.",
  "fuentes": "F03, F30",
  "zona": "optimo",
  "optimo_desde": 15.0,
  "optimo_hasta": 60.0
 },
 {
  "id": "82c14919-d4a8-fbbb-0a30-d93f062024e6",
  "clave": "meditar_10",
  "nombre": "Meditar 10 minutos",
  "categoria": {
   "id": "19e2b6a9-0b8c-43d6-80da-c4ee09d6f454",
   "clave": "bienestar",
   "nombre": "Bienestar",
   "color": "#0F766E",
   "icono": "spa"
  },
  "subcategoria": {
   "id": "ec636f85-8183-4544-938e-a6bcf825e491",
   "clave": "meditacion",
   "nombre": "Meditación",
   "icono": "self_improvement",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 10.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Al despertar",
  "porque": "Sesiones breves de 10 a 20 minutos bastan; practicar más no mejoró más los resultados.",
  "fuentes": "F32",
  "zona": "optimo",
  "optimo_desde": 10.0,
  "optimo_hasta": 20.0
 },
 {
  "id": "06334d21-4c1c-82ca-775f-692871eee71b",
  "clave": "meditar_20",
  "nombre": "Meditar 20 minutos",
  "categoria": {
   "id": "19e2b6a9-0b8c-43d6-80da-c4ee09d6f454",
   "clave": "bienestar",
   "nombre": "Bienestar",
   "color": "#0F766E",
   "icono": "spa"
  },
  "subcategoria": {
   "id": "ec636f85-8183-4544-938e-a6bcf825e491",
   "clave": "meditacion",
   "nombre": "Meditación",
   "icono": "self_improvement",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 20.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Antes de dormir",
  "porque": "Hasta 20 minutos al día está dentro de lo recomendado.",
  "fuentes": "F32",
  "zona": "optimo",
  "optimo_desde": 10.0,
  "optimo_hasta": 20.0
 },
 {
  "id": "f16609f5-afc5-f246-e18e-6d7cac416451",
  "clave": "respiracion_consciente",
  "nombre": "Respiración consciente",
  "categoria": {
   "id": "19e2b6a9-0b8c-43d6-80da-c4ee09d6f454",
   "clave": "bienestar",
   "nombre": "Bienestar",
   "color": "#0F766E",
   "icono": "spa"
  },
  "subcategoria": {
   "id": "ec636f85-8183-4544-938e-a6bcf825e491",
   "clave": "meditacion",
   "nombre": "Meditación",
   "icono": "self_improvement",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 10.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 31,
   "veces_semana": null
  },
  "momento": "En tu pausa del mediodía",
  "porque": "Una práctica breve entre semana es suficiente para notar el efecto.",
  "fuentes": "F32",
  "zona": "optimo",
  "optimo_desde": 10.0,
  "optimo_hasta": 20.0
 },
 {
  "id": "f195e26f-a7e3-9fb2-9ae1-ea2384b4030d",
  "clave": "meditacion_guiada",
  "nombre": "Meditación guiada",
  "categoria": {
   "id": "19e2b6a9-0b8c-43d6-80da-c4ee09d6f454",
   "clave": "bienestar",
   "nombre": "Bienestar",
   "color": "#0F766E",
   "icono": "spa"
  },
  "subcategoria": {
   "id": "ec636f85-8183-4544-938e-a6bcf825e491",
   "clave": "meditacion",
   "nombre": "Meditación",
   "icono": "self_improvement",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 15.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Después de lavarte los dientes en la noche",
  "porque": "Entre 10 y 20 minutos al día es lo recomendado.",
  "fuentes": "F32",
  "zona": "optimo",
  "optimo_desde": 10.0,
  "optimo_hasta": 20.0
 },
 {
  "id": "bab452a4-de6e-4f85-007a-8fd87df2aa9c",
  "clave": "gratitud_semanal",
  "nombre": "Escribir 3 cosas que agradeces",
  "categoria": {
   "id": "19e2b6a9-0b8c-43d6-80da-c4ee09d6f454",
   "clave": "bienestar",
   "nombre": "Bienestar",
   "color": "#0F766E",
   "icono": "spa"
  },
  "subcategoria": {
   "id": "7c1b6619-9e63-45db-9f22-0ca5a3e76984",
   "clave": "gratitud",
   "nombre": "Gratitud",
   "icono": "volunteer_activism",
   "sentido": "aumentar"
  },
  "unidad": "registros",
  "meta": 1.0,
  "frecuencia": {
   "tipo": "n_por_semana",
   "dias_semana": null,
   "veces_semana": 1
  },
  "momento": "El domingo en la noche",
  "porque": "Hacerlo una vez por semana funcionó mejor que tres: la repetición desgasta el efecto.",
  "fuentes": "F36",
  "zona": "optimo",
  "optimo_desde": 1.0,
  "optimo_hasta": 3.0
 },
 {
  "id": "4b0e0e81-aeb1-59bf-2a35-e655f7c65df7",
  "clave": "mensaje_gratitud",
  "nombre": "Enviar un mensaje de agradecimiento",
  "categoria": {
   "id": "19e2b6a9-0b8c-43d6-80da-c4ee09d6f454",
   "clave": "bienestar",
   "nombre": "Bienestar",
   "color": "#0F766E",
   "icono": "spa"
  },
  "subcategoria": {
   "id": "7c1b6619-9e63-45db-9f22-0ca5a3e76984",
   "clave": "gratitud",
   "nombre": "Gratitud",
   "icono": "volunteer_activism",
   "sentido": "aumentar"
  },
  "unidad": "registros",
  "meta": 1.0,
  "frecuencia": {
   "tipo": "n_por_semana",
   "dias_semana": null,
   "veces_semana": 1
  },
  "momento": "Al final de la semana",
  "porque": "Expresar gratitud de forma regular mejoró el bienestar en los estudios.",
  "fuentes": "F35",
  "zona": "optimo",
  "optimo_desde": 1.0,
  "optimo_hasta": 3.0
 },
 {
  "id": "f7f5a05d-8403-628e-3214-c34d9caaa180",
  "clave": "diario_gratitud",
  "nombre": "Diario de gratitud",
  "categoria": {
   "id": "19e2b6a9-0b8c-43d6-80da-c4ee09d6f454",
   "clave": "bienestar",
   "nombre": "Bienestar",
   "color": "#0F766E",
   "icono": "spa"
  },
  "subcategoria": {
   "id": "7c1b6619-9e63-45db-9f22-0ca5a3e76984",
   "clave": "gratitud",
   "nombre": "Gratitud",
   "icono": "volunteer_activism",
   "sentido": "aumentar"
  },
  "unidad": "registros",
  "meta": 1.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 18,
   "veces_semana": null
  },
  "momento": "Antes de dormir, martes y viernes",
  "porque": "Una o pocas veces por semana basta para notar el efecto.",
  "fuentes": "F35, F36",
  "zona": "optimo",
  "optimo_desde": 0.5,
  "optimo_hasta": 1.5
 },
 {
  "id": "ff70dd93-c8fb-496b-519b-bf00c631aa90",
  "clave": "lo_bueno_semana",
  "nombre": "Repasar lo bueno de la semana",
  "categoria": {
   "id": "19e2b6a9-0b8c-43d6-80da-c4ee09d6f454",
   "clave": "bienestar",
   "nombre": "Bienestar",
   "color": "#0F766E",
   "icono": "spa"
  },
  "subcategoria": {
   "id": "7c1b6619-9e63-45db-9f22-0ca5a3e76984",
   "clave": "gratitud",
   "nombre": "Gratitud",
   "icono": "volunteer_activism",
   "sentido": "aumentar"
  },
  "unidad": "registros",
  "meta": 1.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 64,
   "veces_semana": null
  },
  "momento": "El domingo después de cenar",
  "porque": "Detenerte a notar lo bueno una vez por semana mejoró el bienestar.",
  "fuentes": "F35",
  "zona": "optimo",
  "optimo_desde": 1.0,
  "optimo_hasta": 3.0
 },
 {
  "id": "dcf272ea-07be-b47b-9b8b-0343cd4f619e",
  "clave": "redes_2h",
  "nombre": "Limitar redes sociales a 2 horas",
  "categoria": {
   "id": "19e2b6a9-0b8c-43d6-80da-c4ee09d6f454",
   "clave": "bienestar",
   "nombre": "Bienestar",
   "color": "#0F766E",
   "icono": "spa"
  },
  "subcategoria": {
   "id": "5a3f964b-4aae-40aa-a1bd-c20abdf1aa2b",
   "clave": "reducir_pantallas",
   "nombre": "Reducir pantallas",
   "icono": "phonelink_off",
   "sentido": "reducir"
  },
  "unidad": "h",
  "meta": 2.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Activando el límite de tu teléfono",
  "porque": "No hay un número con evidencia firme: ponerte un límite y bajarlo poco a poco con la Escalera es un buen inicio.",
  "fuentes": "F37",
  "zona": "sin_referencia",
  "optimo_desde": null,
  "optimo_hasta": null
 },
 {
  "id": "a1a39378-6023-19f8-164d-59558f1fb20c",
  "clave": "pantallas_noche",
  "nombre": "Limitar pantallas en la noche a 30 minutos",
  "categoria": {
   "id": "19e2b6a9-0b8c-43d6-80da-c4ee09d6f454",
   "clave": "bienestar",
   "nombre": "Bienestar",
   "color": "#0F766E",
   "icono": "spa"
  },
  "subcategoria": {
   "id": "5a3f964b-4aae-40aa-a1bd-c20abdf1aa2b",
   "clave": "reducir_pantallas",
   "nombre": "Reducir pantallas",
   "icono": "phonelink_off",
   "sentido": "reducir"
  },
  "unidad": "min",
  "meta": 30.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Después de cenar",
  "porque": "Usar menos el teléfono por la noche te ayuda a acostarte a tiempo para dormir 7 horas o más.",
  "fuentes": "F37, F18",
  "zona": "sin_referencia",
  "optimo_desde": null,
  "optimo_hasta": null
 },
 {
  "id": "1119b71b-55a0-9e8a-dcfb-10a77d49f42d",
  "clave": "redes_1h",
  "nombre": "Limitar redes sociales a 1 hora",
  "categoria": {
   "id": "19e2b6a9-0b8c-43d6-80da-c4ee09d6f454",
   "clave": "bienestar",
   "nombre": "Bienestar",
   "color": "#0F766E",
   "icono": "spa"
  },
  "subcategoria": {
   "id": "5a3f964b-4aae-40aa-a1bd-c20abdf1aa2b",
   "clave": "reducir_pantallas",
   "nombre": "Reducir pantallas",
   "icono": "phonelink_off",
   "sentido": "reducir"
  },
  "unidad": "h",
  "meta": 1.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Silenciando las notificaciones",
  "porque": "Un límite claro ayuda a usarlas con intención; la Escalera lo ajusta poco a poco.",
  "fuentes": "F37",
  "zona": "sin_referencia",
  "optimo_desde": null,
  "optimo_hasta": null
 },
 {
  "id": "8407578b-ba06-f990-086b-1a82ea9f6924",
  "clave": "pantalla_libre_3h",
  "nombre": "Limitar el tiempo libre de pantalla a 3 horas",
  "categoria": {
   "id": "19e2b6a9-0b8c-43d6-80da-c4ee09d6f454",
   "clave": "bienestar",
   "nombre": "Bienestar",
   "color": "#0F766E",
   "icono": "spa"
  },
  "subcategoria": {
   "id": "5a3f964b-4aae-40aa-a1bd-c20abdf1aa2b",
   "clave": "reducir_pantallas",
   "nombre": "Reducir pantallas",
   "icono": "phonelink_off",
   "sentido": "reducir"
  },
  "unidad": "h",
  "meta": 3.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Revisando tu tiempo de uso cada noche",
  "porque": "Medir tu tiempo de pantalla es el primer paso para reducirlo poco a poco.",
  "fuentes": "F37",
  "zona": "sin_referencia",
  "optimo_desde": null,
  "optimo_hasta": null
 },
 {
  "id": "29e06bd5-3738-5916-427d-847cb39a3067",
  "clave": "llamar_alguien",
  "nombre": "Llamar a un familiar o amigo",
  "categoria": {
   "id": "19e2b6a9-0b8c-43d6-80da-c4ee09d6f454",
   "clave": "bienestar",
   "nombre": "Bienestar",
   "color": "#0F766E",
   "icono": "spa"
  },
  "subcategoria": {
   "id": "559deed5-8ca6-4f78-a609-732c0111153f",
   "clave": "convivencia_social",
   "nombre": "Convivencia social",
   "icono": "groups",
   "sentido": "aumentar"
  },
  "unidad": "veces",
  "meta": 1.0,
  "frecuencia": {
   "tipo": "n_por_semana",
   "dias_semana": null,
   "veces_semana": 3
  },
  "momento": "Después de cenar",
  "porque": "Las relaciones sociales tienen un efecto grande en la salud y en vivir más años.",
  "fuentes": "F38",
  "zona": "sin_referencia",
  "optimo_desde": null,
  "optimo_hasta": null
 },
 {
  "id": "2f394dcb-7e87-9ee8-4c2d-49e9aad37293",
  "clave": "comer_acompanado",
  "nombre": "Comer acompañado",
  "categoria": {
   "id": "19e2b6a9-0b8c-43d6-80da-c4ee09d6f454",
   "clave": "bienestar",
   "nombre": "Bienestar",
   "color": "#0F766E",
   "icono": "spa"
  },
  "subcategoria": {
   "id": "559deed5-8ca6-4f78-a609-732c0111153f",
   "clave": "convivencia_social",
   "nombre": "Convivencia social",
   "icono": "groups",
   "sentido": "aumentar"
  },
  "unidad": "veces",
  "meta": 1.0,
  "frecuencia": {
   "tipo": "n_por_semana",
   "dias_semana": null,
   "veces_semana": 3
  },
  "momento": "En la comida o la cena",
  "porque": "Compartir tiempo con otros fortalece los lazos que protegen tu salud.",
  "fuentes": "F38",
  "zona": "sin_referencia",
  "optimo_desde": null,
  "optimo_hasta": null
 },
 {
  "id": "9e64c3b5-a862-8f1a-2e6f-fa82d5af8cc4",
  "clave": "ver_amigos",
  "nombre": "Ver a tus amigos",
  "categoria": {
   "id": "19e2b6a9-0b8c-43d6-80da-c4ee09d6f454",
   "clave": "bienestar",
   "nombre": "Bienestar",
   "color": "#0F766E",
   "icono": "spa"
  },
  "subcategoria": {
   "id": "559deed5-8ca6-4f78-a609-732c0111153f",
   "clave": "convivencia_social",
   "nombre": "Convivencia social",
   "icono": "groups",
   "sentido": "aumentar"
  },
  "unidad": "veces",
  "meta": 1.0,
  "frecuencia": {
   "tipo": "n_por_semana",
   "dias_semana": null,
   "veces_semana": 1
  },
  "momento": "El fin de semana",
  "porque": "Los lazos sociales fuertes se asocian con vivir más años.",
  "fuentes": "F38",
  "zona": "sin_referencia",
  "optimo_desde": null,
  "optimo_hasta": null
 },
 {
  "id": "d56622f6-da15-0a33-5a13-42eec2261d09",
  "clave": "tiempo_calidad",
  "nombre": "Tiempo de calidad con alguien",
  "categoria": {
   "id": "19e2b6a9-0b8c-43d6-80da-c4ee09d6f454",
   "clave": "bienestar",
   "nombre": "Bienestar",
   "color": "#0F766E",
   "icono": "spa"
  },
  "subcategoria": {
   "id": "559deed5-8ca6-4f78-a609-732c0111153f",
   "clave": "convivencia_social",
   "nombre": "Convivencia social",
   "icono": "groups",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 60.0,
  "frecuencia": {
   "tipo": "n_por_semana",
   "dias_semana": null,
   "veces_semana": 2
  },
  "momento": "Sin el teléfono a la mano",
  "porque": "Dedicar tiempo a las personas cercanas protege tu salud a largo plazo.",
  "fuentes": "F38",
  "zona": "sin_referencia",
  "optimo_desde": null,
  "optimo_hasta": null
 },
 {
  "id": "b06ccd8b-b999-d558-a4ed-c1ac50f132be",
  "clave": "naturaleza_30",
  "nombre": "Tiempo en la naturaleza",
  "categoria": {
   "id": "19e2b6a9-0b8c-43d6-80da-c4ee09d6f454",
   "clave": "bienestar",
   "nombre": "Bienestar",
   "color": "#0F766E",
   "icono": "spa"
  },
  "subcategoria": {
   "id": "3befbcd3-58b6-4c4a-97a8-b15824878bfb",
   "clave": "aire_libre",
   "nombre": "Aire libre",
   "icono": "park",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 30.0,
  "frecuencia": {
   "tipo": "n_por_semana",
   "dias_semana": null,
   "veces_semana": 4
  },
  "momento": "Después del trabajo o la escuela",
  "porque": "Al menos 120 minutos a la semana en la naturaleza se asocian con mejor salud y bienestar.",
  "fuentes": "F39",
  "zona": "optimo",
  "optimo_desde": 30.0,
  "optimo_hasta": 75.0
 },
 {
  "id": "10935914-c3c3-2b28-ac57-0fa69afe7b5d",
  "clave": "paseo_domingo",
  "nombre": "Paseo largo al aire libre",
  "categoria": {
   "id": "19e2b6a9-0b8c-43d6-80da-c4ee09d6f454",
   "clave": "bienestar",
   "nombre": "Bienestar",
   "color": "#0F766E",
   "icono": "spa"
  },
  "subcategoria": {
   "id": "3befbcd3-58b6-4c4a-97a8-b15824878bfb",
   "clave": "aire_libre",
   "nombre": "Aire libre",
   "icono": "park",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 120.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 64,
   "veces_semana": null
  },
  "momento": "El domingo por la mañana",
  "porque": "Los 120 minutos semanales se pueden juntar en una sola salida.",
  "fuentes": "F39",
  "zona": "optimo",
  "optimo_desde": 120.0,
  "optimo_hasta": 300.0
 },
 {
  "id": "672d4417-784e-95a2-c0e4-c254323a54a5",
  "clave": "caminar_parque",
  "nombre": "Caminar en un parque",
  "categoria": {
   "id": "19e2b6a9-0b8c-43d6-80da-c4ee09d6f454",
   "clave": "bienestar",
   "nombre": "Bienestar",
   "color": "#0F766E",
   "icono": "spa"
  },
  "subcategoria": {
   "id": "3befbcd3-58b6-4c4a-97a8-b15824878bfb",
   "clave": "aire_libre",
   "nombre": "Aire libre",
   "icono": "park",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 40.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 21,
   "veces_semana": null
  },
  "momento": "A la hora de la comida",
  "porque": "Tres caminatas de 40 minutos en un parque suman los 120 minutos recomendados.",
  "fuentes": "F39",
  "zona": "optimo",
  "optimo_desde": 40.0,
  "optimo_hasta": 100.0
 },
 {
  "id": "9abb9a07-dd87-0bf8-6eb4-6c4576bdd409",
  "clave": "hora_aire_libre",
  "nombre": "Una hora al aire libre",
  "categoria": {
   "id": "19e2b6a9-0b8c-43d6-80da-c4ee09d6f454",
   "clave": "bienestar",
   "nombre": "Bienestar",
   "color": "#0F766E",
   "icono": "spa"
  },
  "subcategoria": {
   "id": "3befbcd3-58b6-4c4a-97a8-b15824878bfb",
   "clave": "aire_libre",
   "nombre": "Aire libre",
   "icono": "park",
   "sentido": "aumentar"
  },
  "unidad": "min",
  "meta": 60.0,
  "frecuencia": {
   "tipo": "n_por_semana",
   "dias_semana": null,
   "veces_semana": 3
  },
  "momento": "Al salir de clases o del trabajo",
  "porque": "El beneficio llega a su máximo entre 200 y 300 minutos a la semana.",
  "fuentes": "F39",
  "zona": "optimo",
  "optimo_desde": 40.0,
  "optimo_hasta": 100.0
 },
 {
  "id": "bda192a1-1904-aa24-6ad5-255e91eca768",
  "clave": "ahorro_50_semana",
  "nombre": "Apartar 50 pesos a la semana",
  "categoria": {
   "id": "38e5b6de-3845-4024-9acf-113931c03b09",
   "clave": "finanzas",
   "nombre": "Finanzas",
   "color": "#92650A",
   "icono": "savings"
  },
  "subcategoria": {
   "id": "bd9906b3-d4c7-48ea-a13c-bdc739a9c5e5",
   "clave": "ahorro",
   "nombre": "Ahorro",
   "icono": "savings",
   "sentido": "aumentar"
  },
  "unidad": "pesos",
  "meta": 50.0,
  "frecuencia": {
   "tipo": "n_por_semana",
   "dias_semana": null,
   "veces_semana": 1
  },
  "momento": "El día que recibes tu pago",
  "porque": "Una meta concreta y un momento fijo ayudan a cumplirla; el monto lo ajustas con la Escalera.",
  "fuentes": "F06, F04",
  "zona": "sin_referencia",
  "optimo_desde": null,
  "optimo_hasta": null
 },
 {
  "id": "2ad1e467-fbfe-c0c5-fb5f-dfae9e107818",
  "clave": "ahorro_100_semana",
  "nombre": "Apartar 100 pesos a la semana",
  "categoria": {
   "id": "38e5b6de-3845-4024-9acf-113931c03b09",
   "clave": "finanzas",
   "nombre": "Finanzas",
   "color": "#92650A",
   "icono": "savings"
  },
  "subcategoria": {
   "id": "bd9906b3-d4c7-48ea-a13c-bdc739a9c5e5",
   "clave": "ahorro",
   "nombre": "Ahorro",
   "icono": "savings",
   "sentido": "aumentar"
  },
  "unidad": "pesos",
  "meta": 100.0,
  "frecuencia": {
   "tipo": "n_por_semana",
   "dias_semana": null,
   "veces_semana": 1
  },
  "momento": "Antes de gastar en otra cosa",
  "porque": "Apartar primero y gastar después convierte el ahorro en un plan concreto.",
  "fuentes": "F06, F04",
  "zona": "sin_referencia",
  "optimo_desde": null,
  "optimo_hasta": null
 },
 {
  "id": "14354990-0450-68f7-d614-ec9ca031f9ae",
  "clave": "ahorro_20_diario",
  "nombre": "Ahorrar 20 pesos al día",
  "categoria": {
   "id": "38e5b6de-3845-4024-9acf-113931c03b09",
   "clave": "finanzas",
   "nombre": "Finanzas",
   "color": "#92650A",
   "icono": "savings"
  },
  "subcategoria": {
   "id": "bd9906b3-d4c7-48ea-a13c-bdc739a9c5e5",
   "clave": "ahorro",
   "nombre": "Ahorro",
   "icono": "savings",
   "sentido": "aumentar"
  },
  "unidad": "pesos",
  "meta": 20.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Al llegar a casa, en una alcancía",
  "porque": "Hacerlo a la misma hora y en el mismo lugar ayuda a que se vuelva automático.",
  "fuentes": "F03, F06",
  "zona": "sin_referencia",
  "optimo_desde": null,
  "optimo_hasta": null
 },
 {
  "id": "6209bfb3-9066-4507-dcd1-9c5581eb8634",
  "clave": "guardar_monedas",
  "nombre": "Guardar las monedas del día",
  "categoria": {
   "id": "38e5b6de-3845-4024-9acf-113931c03b09",
   "clave": "finanzas",
   "nombre": "Finanzas",
   "color": "#92650A",
   "icono": "savings"
  },
  "subcategoria": {
   "id": "bd9906b3-d4c7-48ea-a13c-bdc739a9c5e5",
   "clave": "ahorro",
   "nombre": "Ahorro",
   "icono": "savings",
   "sentido": "aumentar"
  },
  "unidad": "pesos",
  "meta": 10.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Al vaciar tus bolsillos en la noche",
  "porque": "Asociar el ahorro a algo que ya haces cada noche lo vuelve un hábito.",
  "fuentes": "F03, F04",
  "zona": "sin_referencia",
  "optimo_desde": null,
  "optimo_hasta": null
 },
 {
  "id": "157cbb97-59ed-d8a9-7fc9-3e1b9378cc4c",
  "clave": "ahorro_200_semana",
  "nombre": "Ahorrar 200 pesos a la semana",
  "categoria": {
   "id": "38e5b6de-3845-4024-9acf-113931c03b09",
   "clave": "finanzas",
   "nombre": "Finanzas",
   "color": "#92650A",
   "icono": "savings"
  },
  "subcategoria": {
   "id": "bd9906b3-d4c7-48ea-a13c-bdc739a9c5e5",
   "clave": "ahorro",
   "nombre": "Ahorro",
   "icono": "savings",
   "sentido": "aumentar"
  },
  "unidad": "pesos",
  "meta": 200.0,
  "frecuencia": {
   "tipo": "n_por_semana",
   "dias_semana": null,
   "veces_semana": 1
  },
  "momento": "Con una transferencia automática el día de pago",
  "porque": "Decidir de antemano cuándo y cuánto ahorrar ayuda a cumplirlo.",
  "fuentes": "F04, F06",
  "zona": "sin_referencia",
  "optimo_desde": null,
  "optimo_hasta": null
 },
 {
  "id": "a48b5110-0b6d-842a-6cfb-60b3d970d74f",
  "clave": "ahorro_antojo",
  "nombre": "Ahorrar lo de un antojo",
  "categoria": {
   "id": "38e5b6de-3845-4024-9acf-113931c03b09",
   "clave": "finanzas",
   "nombre": "Finanzas",
   "color": "#92650A",
   "icono": "savings"
  },
  "subcategoria": {
   "id": "bd9906b3-d4c7-48ea-a13c-bdc739a9c5e5",
   "clave": "ahorro",
   "nombre": "Ahorro",
   "icono": "savings",
   "sentido": "aumentar"
  },
  "unidad": "pesos",
  "meta": 30.0,
  "frecuencia": {
   "tipo": "n_por_semana",
   "dias_semana": null,
   "veces_semana": 3
  },
  "momento": "Cuando decidas no comprar algo que no planeabas",
  "porque": "Un plan \"si pasa esto, haré aquello\" convierte la tentación en ahorro.",
  "fuentes": "F04",
  "zona": "sin_referencia",
  "optimo_desde": null,
  "optimo_hasta": null
 },
 {
  "id": "87f2dee4-c464-2713-928e-296a678fca18",
  "clave": "ahorro_entre_semana",
  "nombre": "Ahorrar 30 pesos entre semana",
  "categoria": {
   "id": "38e5b6de-3845-4024-9acf-113931c03b09",
   "clave": "finanzas",
   "nombre": "Finanzas",
   "color": "#92650A",
   "icono": "savings"
  },
  "subcategoria": {
   "id": "bd9906b3-d4c7-48ea-a13c-bdc739a9c5e5",
   "clave": "ahorro",
   "nombre": "Ahorro",
   "icono": "savings",
   "sentido": "aumentar"
  },
  "unidad": "pesos",
  "meta": 30.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 31,
   "veces_semana": null
  },
  "momento": "Al terminar tu jornada",
  "porque": "Una meta pequeña y concreta es más fácil de sostener.",
  "fuentes": "F06",
  "zona": "sin_referencia",
  "optimo_desde": null,
  "optimo_hasta": null
 },
 {
  "id": "9b744740-1887-b6c6-73a2-818bc9ecdcd6",
  "clave": "fondo_emergencias",
  "nombre": "Fondo de emergencias",
  "categoria": {
   "id": "38e5b6de-3845-4024-9acf-113931c03b09",
   "clave": "finanzas",
   "nombre": "Finanzas",
   "color": "#92650A",
   "icono": "savings"
  },
  "subcategoria": {
   "id": "bd9906b3-d4c7-48ea-a13c-bdc739a9c5e5",
   "clave": "ahorro",
   "nombre": "Ahorro",
   "icono": "savings",
   "sentido": "aumentar"
  },
  "unidad": "pesos",
  "meta": 150.0,
  "frecuencia": {
   "tipo": "n_por_semana",
   "dias_semana": null,
   "veces_semana": 1
  },
  "momento": "Cada lunes, antes de planear la semana",
  "porque": "Una meta específica rinde más que \"ahorrar lo que se pueda\".",
  "fuentes": "F06, F04",
  "zona": "sin_referencia",
  "optimo_desde": null,
  "optimo_hasta": null
 },
 {
  "id": "8e2d1fe7-da2e-213c-e863-09a1d747a097",
  "clave": "ahorro_meta",
  "nombre": "Ahorrar para una meta",
  "categoria": {
   "id": "38e5b6de-3845-4024-9acf-113931c03b09",
   "clave": "finanzas",
   "nombre": "Finanzas",
   "color": "#92650A",
   "icono": "savings"
  },
  "subcategoria": {
   "id": "bd9906b3-d4c7-48ea-a13c-bdc739a9c5e5",
   "clave": "ahorro",
   "nombre": "Ahorro",
   "icono": "savings",
   "sentido": "aumentar"
  },
  "unidad": "pesos",
  "meta": 100.0,
  "frecuencia": {
   "tipo": "n_por_semana",
   "dias_semana": null,
   "veces_semana": 2
  },
  "momento": "Después de recibir cualquier ingreso",
  "porque": "Ponerle nombre y monto a lo que quieres lograr te ayuda a cumplirlo.",
  "fuentes": "F06",
  "zona": "sin_referencia",
  "optimo_desde": null,
  "optimo_hasta": null
 },
 {
  "id": "764d3692-65af-392e-7177-c986d30a1d35",
  "clave": "ahorro_cambio",
  "nombre": "Ahorrar el cambio de tus compras",
  "categoria": {
   "id": "38e5b6de-3845-4024-9acf-113931c03b09",
   "clave": "finanzas",
   "nombre": "Finanzas",
   "color": "#92650A",
   "icono": "savings"
  },
  "subcategoria": {
   "id": "bd9906b3-d4c7-48ea-a13c-bdc739a9c5e5",
   "clave": "ahorro",
   "nombre": "Ahorro",
   "icono": "savings",
   "sentido": "aumentar"
  },
  "unidad": "pesos",
  "meta": 20.0,
  "frecuencia": {
   "tipo": "n_por_semana",
   "dias_semana": null,
   "veces_semana": 3
  },
  "momento": "Después de pagar en efectivo",
  "porque": "Asociar el ahorro a un momento que ya ocurre ayuda a que se vuelva automático.",
  "fuentes": "F03, F04",
  "zona": "sin_referencia",
  "optimo_desde": null,
  "optimo_hasta": null
 },
 {
  "id": "5af7c442-dc44-98b3-76eb-07930c2cc1f0",
  "clave": "anotar_gastos",
  "nombre": "Anotar tus gastos del día",
  "categoria": {
   "id": "38e5b6de-3845-4024-9acf-113931c03b09",
   "clave": "finanzas",
   "nombre": "Finanzas",
   "color": "#92650A",
   "icono": "savings"
  },
  "subcategoria": {
   "id": "ac29d9ed-3238-4996-b9f7-a72019b514b3",
   "clave": "control_gastos",
   "nombre": "Control de gastos",
   "icono": "receipt_long",
   "sentido": "aumentar"
  },
  "unidad": "registros",
  "meta": 1.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "Antes de dormir",
  "porque": "Llevar un registro de lo que haces es de las técnicas de cambio de conducta con más efecto.",
  "fuentes": "F53",
  "zona": "sin_referencia",
  "optimo_desde": null,
  "optimo_hasta": null
 },
 {
  "id": "b25a1c34-797f-cd17-3c0c-a0e6bc8d88af",
  "clave": "revisar_gastos_semana",
  "nombre": "Revisar tus gastos de la semana",
  "categoria": {
   "id": "38e5b6de-3845-4024-9acf-113931c03b09",
   "clave": "finanzas",
   "nombre": "Finanzas",
   "color": "#92650A",
   "icono": "savings"
  },
  "subcategoria": {
   "id": "ac29d9ed-3238-4996-b9f7-a72019b514b3",
   "clave": "control_gastos",
   "nombre": "Control de gastos",
   "icono": "receipt_long",
   "sentido": "aumentar"
  },
  "unidad": "registros",
  "meta": 1.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 64,
   "veces_semana": null
  },
  "momento": "El domingo en la tarde",
  "porque": "Revisar lo registrado y compararlo con tu meta ayuda a ajustar a tiempo.",
  "fuentes": "F53, F06",
  "zona": "sin_referencia",
  "optimo_desde": null,
  "optimo_hasta": null
 },
 {
  "id": "0f8a0438-19ff-6b88-9b36-a0c43019e3a7",
  "clave": "anotar_compras_pequenas",
  "nombre": "Anotar cada compra pequeña",
  "categoria": {
   "id": "38e5b6de-3845-4024-9acf-113931c03b09",
   "clave": "finanzas",
   "nombre": "Finanzas",
   "color": "#92650A",
   "icono": "savings"
  },
  "subcategoria": {
   "id": "ac29d9ed-3238-4996-b9f7-a72019b514b3",
   "clave": "control_gastos",
   "nombre": "Control de gastos",
   "icono": "receipt_long",
   "sentido": "aumentar"
  },
  "unidad": "veces",
  "meta": 1.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "En cuanto pagues",
  "porque": "Registrar al momento hace visibles los gastos que se escapan.",
  "fuentes": "F53",
  "zona": "sin_referencia",
  "optimo_desde": null,
  "optimo_hasta": null
 },
 {
  "id": "1e6e613e-b711-22ea-5462-618639b57861",
  "clave": "presupuesto_semana",
  "nombre": "Hacer el presupuesto de la semana",
  "categoria": {
   "id": "38e5b6de-3845-4024-9acf-113931c03b09",
   "clave": "finanzas",
   "nombre": "Finanzas",
   "color": "#92650A",
   "icono": "savings"
  },
  "subcategoria": {
   "id": "ac29d9ed-3238-4996-b9f7-a72019b514b3",
   "clave": "control_gastos",
   "nombre": "Control de gastos",
   "icono": "receipt_long",
   "sentido": "aumentar"
  },
  "unidad": "registros",
  "meta": 1.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 1,
   "veces_semana": null
  },
  "momento": "El lunes por la mañana",
  "porque": "Un plan con montos concretos rinde más que \"gastar menos\".",
  "fuentes": "F06, F53",
  "zona": "sin_referencia",
  "optimo_desde": null,
  "optimo_hasta": null
 },
 {
  "id": "1d13b264-c7f8-4328-47cf-b2326fd3d142",
  "clave": "comparar_precios",
  "nombre": "Comparar precios antes de comprar",
  "categoria": {
   "id": "38e5b6de-3845-4024-9acf-113931c03b09",
   "clave": "finanzas",
   "nombre": "Finanzas",
   "color": "#92650A",
   "icono": "savings"
  },
  "subcategoria": {
   "id": "ac29d9ed-3238-4996-b9f7-a72019b514b3",
   "clave": "control_gastos",
   "nombre": "Control de gastos",
   "icono": "receipt_long",
   "sentido": "aumentar"
  },
  "unidad": "veces",
  "meta": 1.0,
  "frecuencia": {
   "tipo": "n_por_semana",
   "dias_semana": null,
   "veces_semana": 3
  },
  "momento": "Antes de cada compra grande",
  "porque": "Decidir de antemano qué harás en una situación ayuda a cumplirlo.",
  "fuentes": "F04",
  "zona": "sin_referencia",
  "optimo_desde": null,
  "optimo_hasta": null
 },
 {
  "id": "106cc031-51ed-5e31-702f-fec629dc26d1",
  "clave": "lista_super",
  "nombre": "Ir al súper con lista",
  "categoria": {
   "id": "38e5b6de-3845-4024-9acf-113931c03b09",
   "clave": "finanzas",
   "nombre": "Finanzas",
   "color": "#92650A",
   "icono": "savings"
  },
  "subcategoria": {
   "id": "ac29d9ed-3238-4996-b9f7-a72019b514b3",
   "clave": "control_gastos",
   "nombre": "Control de gastos",
   "icono": "receipt_long",
   "sentido": "aumentar"
  },
  "unidad": "veces",
  "meta": 1.0,
  "frecuencia": {
   "tipo": "n_por_semana",
   "dias_semana": null,
   "veces_semana": 1
  },
  "momento": "Antes de salir de casa",
  "porque": "Un plan concreto antes de comprar evita gastos que no tenías previstos.",
  "fuentes": "F04, F06",
  "zona": "sin_referencia",
  "optimo_desde": null,
  "optimo_hasta": null
 },
 {
  "id": "ffd86b5e-cf6b-6e84-cea8-0240c73fc816",
  "clave": "revisar_estado_cuenta",
  "nombre": "Revisar tu estado de cuenta",
  "categoria": {
   "id": "38e5b6de-3845-4024-9acf-113931c03b09",
   "clave": "finanzas",
   "nombre": "Finanzas",
   "color": "#92650A",
   "icono": "savings"
  },
  "subcategoria": {
   "id": "ac29d9ed-3238-4996-b9f7-a72019b514b3",
   "clave": "control_gastos",
   "nombre": "Control de gastos",
   "icono": "receipt_long",
   "sentido": "aumentar"
  },
  "unidad": "registros",
  "meta": 1.0,
  "frecuencia": {
   "tipo": "n_por_semana",
   "dias_semana": null,
   "veces_semana": 1
  },
  "momento": "El día que llega tu estado de cuenta",
  "porque": "Revisar lo que ya pasó es una forma de automonitoreo, de las técnicas con más efecto.",
  "fuentes": "F53",
  "zona": "sin_referencia",
  "optimo_desde": null,
  "optimo_hasta": null
 },
 {
  "id": "c996731d-2de6-c1e1-a4c7-043b0bbae585",
  "clave": "esperar_24h",
  "nombre": "Esperar 24 horas antes de una compra no planeada",
  "categoria": {
   "id": "38e5b6de-3845-4024-9acf-113931c03b09",
   "clave": "finanzas",
   "nombre": "Finanzas",
   "color": "#92650A",
   "icono": "savings"
  },
  "subcategoria": {
   "id": "ac29d9ed-3238-4996-b9f7-a72019b514b3",
   "clave": "control_gastos",
   "nombre": "Control de gastos",
   "icono": "receipt_long",
   "sentido": "aumentar"
  },
  "unidad": "veces",
  "meta": 1.0,
  "frecuencia": {
   "tipo": "n_por_semana",
   "dias_semana": null,
   "veces_semana": 2
  },
  "momento": "Cuando quieras comprar algo que no planeabas",
  "porque": "Un plan \"si quiero comprar algo, espero un día\" te ayuda a decidir con calma.",
  "fuentes": "F04",
  "zona": "sin_referencia",
  "optimo_desde": null,
  "optimo_hasta": null
 },
 {
  "id": "e36180ae-e649-fbcf-c687-27eaddef56f7",
  "clave": "ingresos_y_gastos",
  "nombre": "Anotar tus ingresos y gastos",
  "categoria": {
   "id": "38e5b6de-3845-4024-9acf-113931c03b09",
   "clave": "finanzas",
   "nombre": "Finanzas",
   "color": "#92650A",
   "icono": "savings"
  },
  "subcategoria": {
   "id": "ac29d9ed-3238-4996-b9f7-a72019b514b3",
   "clave": "control_gastos",
   "nombre": "Control de gastos",
   "icono": "receipt_long",
   "sentido": "aumentar"
  },
  "unidad": "registros",
  "meta": 2.0,
  "frecuencia": {
   "tipo": "diaria",
   "dias_semana": null,
   "veces_semana": null
  },
  "momento": "En la noche, en tu app o libreta",
  "porque": "Registrar lo que entra y lo que sale te da una foto completa para decidir.",
  "fuentes": "F53",
  "zona": "sin_referencia",
  "optimo_desde": null,
  "optimo_hasta": null
 },
 {
  "id": "44416301-9899-bc58-a0f7-eecce84ced73",
  "clave": "planear_comidas",
  "nombre": "Planear las comidas de la semana",
  "categoria": {
   "id": "38e5b6de-3845-4024-9acf-113931c03b09",
   "clave": "finanzas",
   "nombre": "Finanzas",
   "color": "#92650A",
   "icono": "savings"
  },
  "subcategoria": {
   "id": "ac29d9ed-3238-4996-b9f7-a72019b514b3",
   "clave": "control_gastos",
   "nombre": "Control de gastos",
   "icono": "receipt_long",
   "sentido": "aumentar"
  },
  "unidad": "veces",
  "meta": 1.0,
  "frecuencia": {
   "tipo": "dias_semana",
   "dias_semana": 64,
   "veces_semana": null
  },
  "momento": "El domingo, antes de ir al súper",
  "porque": "Planear con anticipación evita compras de último momento.",
  "fuentes": "F04, F06",
  "zona": "sin_referencia",
  "optimo_desde": null,
  "optimo_hasta": null
 }
]
''';
