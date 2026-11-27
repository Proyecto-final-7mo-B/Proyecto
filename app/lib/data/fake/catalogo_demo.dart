// GENERADO: no editar a mano.
//
// Catálogo con respaldo científico tal como lo devuelve `GET /categorias` (contrato v1.6, §6.3), con los MISMOS ids
// que el clúster. Sale de la base (db/cambios/2026-11-27_evidencia_cientifica.sql) con la consulta de
// `app/docs/modulos/07_habitos.md` (sección "Catálogo del modo fake"). Los rangos y sus fuentes están en
// Evidencias_generales/12_investigacion_cientifica/03_rangos_por_subcategoria.md.
// ignore_for_file: lines_longer_than_80_chars

/// JSON del catálogo de 5 categorías y 22 subcategorías.
const String catalogoDemoJson = r'''
[
 {
  "id": "ed1867f2-83b3-45a9-b27e-4f650f36c275",
  "clave": "ejercicio",
  "color": "#D9480F",
  "icono": "fitness_center",
  "nombre": "Ejercicio",
  "subcategorias": [
   {
    "id": "d851b381-e60e-44cc-8bfe-1b9ec18487b1",
    "clave": "aerobico_moderado",
    "icono": "directions_bike",
    "nombre": "Aeróbico moderado",
    "sentido": "aumentar",
    "unidades": [
     {
      "paso": 5,
      "maximo": 1440,
      "minimo": 1,
      "unidad": "min",
      "factor_a_base": 1
     },
     {
      "paso": 0.25,
      "maximo": 24,
      "minimo": 0.25,
      "unidad": "h",
      "factor_a_base": 60
     },
     {
      "paso": 0.5,
      "maximo": 200,
      "minimo": 0.5,
      "unidad": "km",
      "factor_a_base": null
     }
    ],
    "referencia": {
     "url": "https://doi.org/10.1136/bjsports-2020-102955",
     "cita": "OMS 2020: 150–300 min/semana; Lee 2022: sin beneficio extra después de 600",
     "nota": "De 300 a 600 ya no hace falta subir; arriba de 600 (≈85 min/día) no hay beneficio adicional.",
     "maximo": 600,
     "fuentes": "F11, F12, F13",
     "periodo": "semana",
     "confianza": "alta",
     "piso_bajada": null,
     "unidad_base": "min",
     "optimo_desde": 150,
     "optimo_hasta": 300
    }
   },
   {
    "id": "78557c27-d715-414a-b911-f10edebc8244",
    "clave": "vigoroso",
    "icono": "directions_run",
    "nombre": "Vigoroso",
    "sentido": "aumentar",
    "unidades": [
     {
      "paso": 5,
      "maximo": 1440,
      "minimo": 1,
      "unidad": "min",
      "factor_a_base": 1
     },
     {
      "paso": 0.5,
      "maximo": 200,
      "minimo": 0.5,
      "unidad": "km",
      "factor_a_base": null
     }
    ],
    "referencia": {
     "url": "https://doi.org/10.1161/CIRCULATIONAHA.121.058162",
     "cita": "OMS 2020: 75–150 min/semana; Lee 2022: sin beneficio extra después de 300",
     "nota": "Arriba de 300 min/semana: días de descanso y supervisión profesional.",
     "maximo": 300,
     "fuentes": "F11, F12",
     "periodo": "semana",
     "confianza": "alta",
     "piso_bajada": null,
     "unidad_base": "min",
     "optimo_desde": 75,
     "optimo_hasta": 150
    }
   },
   {
    "id": "d7366413-4c61-4b7e-b39f-1cc0dc0ce925",
    "clave": "fuerza",
    "icono": "fitness_center",
    "nombre": "Fuerza",
    "sentido": "aumentar",
    "unidades": [
     {
      "paso": 5,
      "maximo": 600,
      "minimo": 1,
      "unidad": "min",
      "factor_a_base": 1
     },
     {
      "paso": 1,
      "maximo": 2000,
      "minimo": 1,
      "unidad": "repeticiones",
      "factor_a_base": null
     }
    ],
    "referencia": {
     "url": "https://pubmed.ncbi.nlm.nih.gov/35228201/",
     "cita": "OMS 2020: ≥2 días/semana; Momma 2022: máximo beneficio en 30–60 min/semana",
     "nota": "Curva en J: con más de 60 min/semana el beneficio adicional es incierto.",
     "maximo": null,
     "fuentes": "F11, F14",
     "periodo": "semana",
     "confianza": "baja",
     "piso_bajada": null,
     "unidad_base": "min",
     "optimo_desde": 30,
     "optimo_hasta": 60
    }
   },
   {
    "id": "6184a58c-a1fc-41ca-a246-35455dd2ddad",
    "clave": "pasos",
    "icono": "directions_walk",
    "nombre": "Pasos",
    "sentido": "aumentar",
    "unidades": [
     {
      "paso": 500,
      "maximo": 60000,
      "minimo": 500,
      "unidad": "pasos",
      "factor_a_base": 1
     }
    ],
    "referencia": {
     "url": "https://doi.org/10.1016/S2468-2667(21)00302-9",
     "cita": "Paluch 2022: el beneficio se estabiliza en 8,000–10,000 pasos/día",
     "nota": "Para 60 años o más el beneficio se estabiliza en 6,000–8,000.",
     "maximo": null,
     "fuentes": "F15",
     "periodo": "dia",
     "confianza": "alta",
     "piso_bajada": null,
     "unidad_base": "pasos",
     "optimo_desde": 8000,
     "optimo_hasta": 10000
    }
   },
   {
    "id": "34b5aca8-cb1a-45f7-9f63-b454c535e477",
    "clave": "estiramiento",
    "icono": "accessibility_new",
    "nombre": "Estiramiento",
    "sentido": "aumentar",
    "unidades": [
     {
      "paso": 1,
      "maximo": 600,
      "minimo": 1,
      "unidad": "min",
      "factor_a_base": 1
     }
    ],
    "referencia": {
     "url": "https://doi.org/10.1249/MSS.0b013e318213fefb",
     "cita": "ACSM 2011: 60 s por ejercicio en cada grupo muscular, ≥2 días/semana",
     "nota": "Hacerlo a diario es lo más eficaz.",
     "maximo": null,
     "fuentes": "F16",
     "periodo": "semana",
     "confianza": "media",
     "piso_bajada": null,
     "unidad_base": "min",
     "optimo_desde": 20,
     "optimo_hasta": 70
    }
   },
   {
    "id": "c91f57b0-2064-42c6-a390-ff9f23fbe86d",
    "clave": "pausas_activas",
    "icono": "timer",
    "nombre": "Pausas activas",
    "sentido": "aumentar",
    "unidades": [
     {
      "paso": 1,
      "maximo": 48,
      "minimo": 1,
      "unidad": "pausas",
      "factor_a_base": 1
     }
    ],
    "referencia": {
     "url": "https://pubmed.ncbi.nlm.nih.gov/22374636/",
     "cita": "OMS 2020: reducir el sedentarismo; Dunstan 2012: pausas frecuentes",
     "nota": "Una pausa cada 30–60 min en una jornada de 8 h.",
     "maximo": null,
     "fuentes": "F11, F17",
     "periodo": "dia",
     "confianza": "baja",
     "piso_bajada": null,
     "unidad_base": "pausas",
     "optimo_desde": 8,
     "optimo_hasta": 16
    }
   }
  ]
 },
 {
  "id": "0fe8d75e-c905-4c62-9b92-2530603daa11",
  "clave": "salud",
  "color": "#3F7D20",
  "icono": "favorite",
  "nombre": "Salud",
  "subcategorias": [
   {
    "id": "a5a74ba6-ff76-49fc-8870-20fbed95a3b0",
    "clave": "hidratacion",
    "icono": "water_drop",
    "nombre": "Hidratación",
    "sentido": "aumentar",
    "unidades": [
     {
      "paso": 0.25,
      "maximo": 10,
      "minimo": 0.25,
      "unidad": "L",
      "factor_a_base": 1
     },
     {
      "paso": 1,
      "maximo": 40,
      "minimo": 1,
      "unidad": "vasos",
      "factor_a_base": 0.25
     },
     {
      "paso": 250,
      "maximo": 10000,
      "minimo": 250,
      "unidad": "ml",
      "factor_a_base": 0.001
     }
    ],
    "referencia": {
     "url": "https://doi.org/10.2903/j.efsa.2010.1459",
     "cita": "EFSA 2010 y NASEM 2004: 1.5–3 L de bebidas al día",
     "nota": "No bebas más de 1 L por hora (riesgo de hiponatremia). Con calor o ejercicio intenso se necesita más.",
     "maximo": 4,
     "fuentes": "F20, F21, F22",
     "periodo": "dia",
     "confianza": "media",
     "piso_bajada": 1.5,
     "unidad_base": "L",
     "optimo_desde": 1.5,
     "optimo_hasta": 3
    }
   },
   {
    "id": "a30f00ea-dca5-45c9-93fb-0a32bdb5d92f",
    "clave": "sueno",
    "icono": "bedtime",
    "nombre": "Sueño",
    "sentido": "aumentar",
    "unidades": [
     {
      "paso": 0.25,
      "maximo": 16,
      "minimo": 1,
      "unidad": "h",
      "factor_a_base": 1
     },
     {
      "paso": 15,
      "maximo": 960,
      "minimo": 60,
      "unidad": "min",
      "factor_a_base": 0.016667
     }
    ],
    "referencia": {
     "url": "https://pubmed.ncbi.nlm.nih.gov/25979105/",
     "cita": "AASM/SRS 2015 y NSF 2015: adultos 7–9 h",
     "nota": "Mayores de 65: 7–8 h. Dormir más de 10 h de forma habitual no se recomienda en adultos.",
     "maximo": 10,
     "fuentes": "F18, F19",
     "periodo": "dia",
     "confianza": "alta",
     "piso_bajada": 7,
     "unidad_base": "h",
     "optimo_desde": 7,
     "optimo_hasta": 9
    }
   },
   {
    "id": "04ad3096-c1f8-4dc5-a20d-57b114be4b58",
    "clave": "frutas_verduras",
    "icono": "eco",
    "nombre": "Frutas y verduras",
    "sentido": "aumentar",
    "unidades": [
     {
      "paso": 1,
      "maximo": 20,
      "minimo": 1,
      "unidad": "porciones",
      "factor_a_base": 1
     },
     {
      "paso": 50,
      "maximo": 2000,
      "minimo": 50,
      "unidad": "g",
      "factor_a_base": 0.0125
     }
    ],
    "referencia": {
     "url": "https://doi.org/10.1093/ije/dyw319",
     "cita": "OMS: ≥400 g/día; Aune 2017: beneficio hasta 800 g/día",
     "nota": "Una porción ≈ 80 g; no cuentan papa ni otros tubérculos.",
     "maximo": null,
     "fuentes": "F23, F24",
     "periodo": "dia",
     "confianza": "alta",
     "piso_bajada": null,
     "unidad_base": "porciones",
     "optimo_desde": 5,
     "optimo_hasta": 10
    }
   },
   {
    "id": "6bd22c97-bf54-49de-a3c3-d03b9f6bf55a",
    "clave": "reducir_azucar",
    "icono": "cookie",
    "nombre": "Reducir azúcar",
    "sentido": "reducir",
    "unidades": [
     {
      "paso": 5,
      "maximo": 500,
      "minimo": 1,
      "unidad": "g",
      "factor_a_base": 1
     },
     {
      "paso": 1,
      "maximo": 100,
      "minimo": 1,
      "unidad": "cucharaditas",
      "factor_a_base": 4
     }
    ],
    "referencia": {
     "url": "https://www.who.int/news-room/fact-sheets/detail/healthy-diet",
     "cita": "OMS: azúcares libres < 10 % de la energía (≈50 g), ideal < 5 % (≈25 g)",
     "nota": null,
     "maximo": 50,
     "fuentes": "F23",
     "periodo": "dia",
     "confianza": "alta",
     "piso_bajada": null,
     "unidad_base": "g",
     "optimo_desde": 0,
     "optimo_hasta": 25
    }
   },
   {
    "id": "6243db2e-c2be-4c3d-b092-58a4f9b901b8",
    "clave": "reducir_alcohol",
    "icono": "no_drinks",
    "nombre": "Reducir alcohol",
    "sentido": "reducir",
    "unidades": [
     {
      "paso": 1,
      "maximo": 100,
      "minimo": 1,
      "unidad": "bebidas",
      "factor_a_base": 1
     }
    ],
    "referencia": {
     "url": "https://ccsa.ca/canadas-guidance-alcohol-and-health-final-report",
     "cita": "OMS 2023: ningún nivel es seguro; Canadá 2023: 1–2 por semana riesgo bajo",
     "nota": "3–6 bebidas por semana: riesgo moderado; 7 o más: riesgo cada vez más alto.",
     "maximo": 6,
     "fuentes": "F25, F26",
     "periodo": "semana",
     "confianza": "media",
     "piso_bajada": null,
     "unidad_base": "bebidas",
     "optimo_desde": 0,
     "optimo_hasta": 2
    }
   },
   {
    "id": "8327cc28-f178-44b7-b66c-c4ae4cb79f23",
    "clave": "dejar_fumar",
    "icono": "smoke_free",
    "nombre": "Dejar de fumar",
    "sentido": "reducir",
    "unidades": [
     {
      "paso": 1,
      "maximo": 100,
      "minimo": 1,
      "unidad": "cigarros",
      "factor_a_base": 1
     }
    ],
    "referencia": {
     "url": "https://doi.org/10.1136/bmj.j5855",
     "cita": "Hackshaw 2018: no hay un nivel seguro de tabaco",
     "nota": "La meta final es dejarlo; la Escalera baja el límite poco a poco.",
     "maximo": null,
     "fuentes": "F27",
     "periodo": "dia",
     "confianza": "alta",
     "piso_bajada": null,
     "unidad_base": "cigarros",
     "optimo_desde": 0,
     "optimo_hasta": 0
    }
   }
  ]
 },
 {
  "id": "a7caa85f-4896-4484-9ea5-b648cc42c683",
  "clave": "educacion",
  "color": "#2563EB",
  "icono": "school",
  "nombre": "Educación",
  "subcategorias": [
   {
    "id": "3bdc6868-b2df-4efe-bd11-60508d2a3d85",
    "clave": "lectura",
    "icono": "menu_book",
    "nombre": "Lectura",
    "sentido": "aumentar",
    "unidades": [
     {
      "paso": 5,
      "maximo": 1440,
      "minimo": 1,
      "unidad": "min",
      "factor_a_base": 1
     },
     {
      "paso": 1,
      "maximo": 1000,
      "minimo": 1,
      "unidad": "páginas",
      "factor_a_base": 1.25
     }
    ],
    "referencia": {
     "url": "https://pmc.ncbi.nlm.nih.gov/articles/PMC5105607",
     "cita": "Bavishi 2016: beneficio mayor con más de 3.5 h/semana (≈30 min/día)",
     "nota": "Asociación observacional. Páginas → minutos con 238 palabras/min (Brysbaert 2019).",
     "maximo": null,
     "fuentes": "F28, F29",
     "periodo": "semana",
     "confianza": "baja",
     "piso_bajada": null,
     "unidad_base": "min",
     "optimo_desde": 210,
     "optimo_hasta": 420
    }
   },
   {
    "id": "beef97ba-c3de-49ba-98b0-d116ee92e284",
    "clave": "estudio",
    "icono": "edit_note",
    "nombre": "Estudio",
    "sentido": "aumentar",
    "unidades": [
     {
      "paso": 5,
      "maximo": 1440,
      "minimo": 1,
      "unidad": "min",
      "factor_a_base": 1
     },
     {
      "paso": 0.25,
      "maximo": 24,
      "minimo": 0.25,
      "unidad": "h",
      "factor_a_base": 60
     }
    ],
    "referencia": {
     "url": "https://doi.org/10.1037/0033-295X.100.3.363",
     "cita": "Ericsson 1993: ≈4 h/día de práctica deliberada como máximo; Cepeda 2006: repartir",
     "nota": "Mejor en bloques repartidos que todo seguido.",
     "maximo": 240,
     "fuentes": "F30, F31",
     "periodo": "dia",
     "confianza": "baja",
     "piso_bajada": null,
     "unidad_base": "min",
     "optimo_desde": 30,
     "optimo_hasta": 180
    }
   },
   {
    "id": "19ed515c-78b4-4b8f-8fd0-e3720243d043",
    "clave": "idiomas",
    "icono": "translate",
    "nombre": "Idiomas",
    "sentido": "aumentar",
    "unidades": [
     {
      "paso": 5,
      "maximo": 1440,
      "minimo": 1,
      "unidad": "min",
      "factor_a_base": 1
     }
    ],
    "referencia": {
     "url": "https://doi.org/10.1037/0033-2909.132.3.354",
     "cita": "Cepeda 2006: práctica espaciada; Ericsson 1993: tope de ≈4 h/día",
     "nota": "Rango práctico: no hay estudios de dosis diaria.",
     "maximo": 240,
     "fuentes": "F30, F31",
     "periodo": "dia",
     "confianza": "baja",
     "piso_bajada": null,
     "unidad_base": "min",
     "optimo_desde": 15,
     "optimo_hasta": 60
    }
   }
  ]
 },
 {
  "id": "19e2b6a9-0b8c-43d6-80da-c4ee09d6f454",
  "clave": "bienestar",
  "color": "#0F766E",
  "icono": "spa",
  "nombre": "Bienestar",
  "subcategorias": [
   {
    "id": "ec636f85-8183-4544-938e-a6bcf825e491",
    "clave": "meditacion",
    "icono": "self_improvement",
    "nombre": "Meditación",
    "sentido": "aumentar",
    "unidades": [
     {
      "paso": 1,
      "maximo": 600,
      "minimo": 1,
      "unidad": "min",
      "factor_a_base": 1
     }
    ],
    "referencia": {
     "url": "https://doi.org/10.1007/s12671-020-01319-4",
     "cita": "Strohmaier 2020: más minutos no mejoran el ánimo; MBSR ≈45 min/día",
     "nota": "Si notas malestar al meditar, haz una pausa (Britton 2021).",
     "maximo": 45,
     "fuentes": "F32, F33, F34",
     "periodo": "dia",
     "confianza": "media",
     "piso_bajada": null,
     "unidad_base": "min",
     "optimo_desde": 10,
     "optimo_hasta": 20
    }
   },
   {
    "id": "7c1b6619-9e63-45db-9f22-0ca5a3e76984",
    "clave": "gratitud",
    "icono": "volunteer_activism",
    "nombre": "Gratitud",
    "sentido": "aumentar",
    "unidades": [
     {
      "paso": 1,
      "maximo": 21,
      "minimo": 1,
      "unidad": "registros",
      "factor_a_base": 1
     }
    ],
    "referencia": {
     "url": "https://doi.org/10.1037/0022-3514.84.2.377",
     "cita": "Emmons 2003; Lyubomirsky 2005: 1 vez por semana funcionó mejor que 3",
     "nota": "Repetirlo demasiado desgasta el efecto.",
     "maximo": null,
     "fuentes": "F35, F36",
     "periodo": "semana",
     "confianza": "baja",
     "piso_bajada": null,
     "unidad_base": "registros",
     "optimo_desde": 1,
     "optimo_hasta": 3
    }
   },
   {
    "id": "5a3f964b-4aae-40aa-a1bd-c20abdf1aa2b",
    "clave": "reducir_pantallas",
    "icono": "phonelink_off",
    "nombre": "Reducir pantallas",
    "sentido": "reducir",
    "unidades": [
     {
      "paso": 5,
      "maximo": 1440,
      "minimo": 5,
      "unidad": "min",
      "factor_a_base": 1
     },
     {
      "paso": 0.25,
      "maximo": 24,
      "minimo": 0.25,
      "unidad": "h",
      "factor_a_base": 60
     }
    ],
    "referencia": null
   },
   {
    "id": "559deed5-8ca6-4f78-a609-732c0111153f",
    "clave": "convivencia_social",
    "icono": "groups",
    "nombre": "Convivencia social",
    "sentido": "aumentar",
    "unidades": [
     {
      "paso": 1,
      "maximo": 21,
      "minimo": 1,
      "unidad": "veces",
      "factor_a_base": 1
     },
     {
      "paso": 15,
      "maximo": 1440,
      "minimo": 15,
      "unidad": "min",
      "factor_a_base": 1
     }
    ],
    "referencia": null
   },
   {
    "id": "3befbcd3-58b6-4c4a-97a8-b15824878bfb",
    "clave": "aire_libre",
    "icono": "park",
    "nombre": "Aire libre",
    "sentido": "aumentar",
    "unidades": [
     {
      "paso": 10,
      "maximo": 1440,
      "minimo": 10,
      "unidad": "min",
      "factor_a_base": 1
     },
     {
      "paso": 0.25,
      "maximo": 24,
      "minimo": 0.25,
      "unidad": "h",
      "factor_a_base": 60
     }
    ],
    "referencia": {
     "url": "https://doi.org/10.1038/s41598-019-44097-3",
     "cita": "White 2019: beneficio desde 120 min/semana, máximo en 200–300",
     "nota": "Se puede repartir en varias salidas.",
     "maximo": null,
     "fuentes": "F39",
     "periodo": "semana",
     "confianza": "media",
     "piso_bajada": null,
     "unidad_base": "min",
     "optimo_desde": 120,
     "optimo_hasta": 300
    }
   }
  ]
 },
 {
  "id": "38e5b6de-3845-4024-9acf-113931c03b09",
  "clave": "finanzas",
  "color": "#92650A",
  "icono": "savings",
  "nombre": "Finanzas",
  "subcategorias": [
   {
    "id": "bd9906b3-d4c7-48ea-a13c-bdc739a9c5e5",
    "clave": "ahorro",
    "icono": "savings",
    "nombre": "Ahorro",
    "sentido": "aumentar",
    "unidades": [
     {
      "paso": 10,
      "maximo": 1000000,
      "minimo": 10,
      "unidad": "pesos",
      "factor_a_base": 1
     }
    ],
    "referencia": null
   },
   {
    "id": "ac29d9ed-3238-4996-b9f7-a72019b514b3",
    "clave": "control_gastos",
    "icono": "receipt_long",
    "nombre": "Control de gastos",
    "sentido": "aumentar",
    "unidades": [
     {
      "paso": 1,
      "maximo": 50,
      "minimo": 1,
      "unidad": "registros",
      "factor_a_base": 1
     },
     {
      "paso": 1,
      "maximo": 50,
      "minimo": 1,
      "unidad": "veces",
      "factor_a_base": 1
     }
    ],
    "referencia": null
   }
  ]
 }
]
''';
