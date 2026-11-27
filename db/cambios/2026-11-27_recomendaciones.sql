-- =====================================================================
-- Kaizen · Cambios del 27-nov-2026 (2): hábitos recomendados, fuentes y días protegidos
-- Origen: revisión de Jael de la app (27-nov-2026).
--
--   1. fuente_cientifica: las 53 fuentes de 12_investigacion_cientifica/fuentes.md,
--      para la sección "Acerca de Kaizen" (la app deja de mostrar la fuente fuera
--      del detalle del hábito)
--   2. habito_recomendado: 100 hábitos saludables (20 por categoría, repartidos por
--      subcategoría) con nombre, meta, frecuencia, momento sugerido y por qué.
--      Cada meta está en el óptimo de su subcategoría (salvo "dejar de fumar", donde
--      el óptimo es 0 y la Escalera baja poco a poco)
--   3. habito.recomendacion_id: crear un hábito desde una recomendación. La base
--      copia nombre, subcategoría, unidad, meta, frecuencia e intención; el usuario
--      solo elige la prioridad (y la cápsula, que es aparte)
--   4. fn_dias_protegidos: los días que perdonó el protector de racha, para marcarlos
--      con un escudo en el calendario
--   5. Administración de las recomendaciones y permisos
--
-- Requiere 2026-11-27_evidencia_cientifica.sql. Se ejecuta UNA vez como postgres en
-- el PRIMARIO, en una transacción.
-- Código nuevo: KZ018 recomendación no disponible (inactiva o inexistente).
-- Reversión: 2026-11-27_recomendaciones_revertir.sql
-- IA: asistido (Claude). Revisión: Jael Contreras.
-- =====================================================================
\set ON_ERROR_STOP on
BEGIN;
SET LOCAL ROLE kaizen_owner;
SET LOCAL search_path = kaizen, pg_temp;

-- =====================================================================
-- 1. Fuentes científicas
-- =====================================================================
CREATE TABLE fuente_cientifica (
    clave       text PRIMARY KEY CHECK (clave ~ '^F[0-9]{2}$'),
    tema        text NOT NULL CHECK (tema IN ('formacion', 'actividad', 'salud', 'educacion', 'bienestar',
                                              'color', 'notificaciones')),
    referencia  text NOT NULL CHECK (length(referencia) BETWEEN 10 AND 600),
    enlace      text NOT NULL CHECK (length(enlace) BETWEEN 5 AND 400),
    dato        text NOT NULL CHECK (length(dato) BETWEEN 5 AND 800),
    verificada  text NOT NULL,
    confianza   text NOT NULL
);
COMMENT ON TABLE fuente_cientifica IS
    'Bibliografía de la app (copia de 12_investigacion_cientifica/fuentes.md). La citan referencia_cientifica, logro y habito_recomendado por su clave F##.';

-- Generado desde fuentes.md (sin el formato Markdown)
INSERT INTO fuente_cientifica (clave, tema, referencia, enlace, dato, verificada, confianza) VALUES
 ('F01', 'formacion', 'Lally, P., van Jaarsveld, C. H. M., Potts, H. W. W. y Wardle, J. (2010). How are habits formed: Modelling habit formation in the real world. European Journal of Social Psychology, 40(6), 998–1009.', '10.1002/ejsp.674 · nota de UCL: https://www.ucl.ac.uk/news/2009/aug/how-long-does-it-take-form-habit', 'Llegar al 95 % de la automaticidad tomó de 18 a 254 días; fallar una vez no afectó de forma importante la formación; la automaticidad sigue una curva asintótica. La cifra de 66 días es el promedio o la mediana de quienes ajustaron bien el modelo (n = 39)', 'Sí: el resumen da el rango y lo de fallar una vez. Parcial: el 66 aparece en la nota de UCL y en F02', 'Media (96 participantes, automaticidad autorreportada)'),
 ('F02', 'formacion', 'Singh, B., Murphy, A., Maher, C. y Smith, A. E. (2024). Time to form a habit: A systematic review and meta-analysis of health behaviour habit formation and its determinants. Healthcare, 12(23), 2488.', 'https://pubmed.ncbi.nlm.nih.gov/39685110/', '20 estudios (n = 2,601); 4 midieron el tiempo: medianas de 59–66 días, medias de 106–154, rango de 4–335. Los hábitos de mañana y los elegidos por la persona fueron más fuertes', 'Sí', 'Media'),
 ('F03', 'formacion', 'Wood, W. y Neal, D. T. (2007). A new look at habits and the habit-goal interface. Psychological Review, 114(4), 843–863.', '10.1037/0033-295X.114.4.843', 'El hábito se forma al asociar una respuesta con señales del contexto en que se repite; una vez formado, el contexto lo dispara sin necesidad de la meta', 'Sí', 'Alta (revisión teórica muy citada)'),
 ('F04', 'formacion', 'Gollwitzer, P. M. y Sheeran, P. (2006). Implementation intentions and goal achievement: A meta-analysis of effects and processes. Advances in Experimental Social Psychology, 38, 69–119.', '10.1016/S0065-2601(06)38002-1', 'Intenciones de implementación ("si X, entonces haré Y"): d = 0.65 en 94 pruebas con más de 8,000 participantes', 'Sí', 'Alta'),
 ('F05', 'formacion', 'Kaushal, N. y Rhodes, R. E. (2015). Exercise habit formation in new gym members: A longitudinal study. Journal of Behavioral Medicine, 38, 652–663.', 'https://pubmed.ncbi.nlm.nih.gov/25851609/', 'Para formar el hábito del gimnasio se necesitaron al menos 4 sesiones por semana durante unas 6 semanas', 'Sí', 'Media'),
 ('F06', 'formacion', 'Locke, E. A. y Latham, G. P. (2002). Building a practically useful theory of goal setting and task motivation: A 35-year odyssey. American Psychologist, 57(9), 705–717.', '10.1037/0003-066X.57.9.705', 'Las metas específicas y alcanzables pero retadoras rinden más que "haz lo que puedas"', 'Sí', 'Alta'),
 ('F07', 'formacion', 'Buist, I., Bredeweg, S. W., van Mechelen, W., Lemmink, K. A. P. M., Pepping, G.-J. y Diercks, R. L. (2008). No effect of a graded training program on the number of running-related injuries in novice runners: A randomized controlled trial. American Journal of Sports Medicine, 36(1), 33–39.', 'https://research.rug.nl/en/publications/no-effect-of-a-graded-training-program-on-the-number-of-running-r/', 'Aumentar el 10 % por semana no redujo las lesiones (20.8 % contra 20.3 %; p = .90)', 'Sí', 'Alta (que la "regla del 10 %" no está probada)'),
 ('F08', 'formacion', 'Nielsen, R. Ø. et al. (2014). Excessive progression in weekly running distance and risk of running-related injuries. Journal of Orthopaedic & Sports Physical Therapy, 44(10), 739–747.', 'https://pmc.ncbi.nlm.nih.gov/articles/PMC4060311', 'Subir más de 30 % la distancia semanal en 2 semanas se asoció con más lesiones de sobrecarga', 'Sí', 'Baja–media'),
 ('F09', 'formacion', 'Silverman, J. y Barasch, A. (2023). On or off track: How (broken) streaks affect consumer decisions. Journal of Consumer Research, 49(6), 1095–1117.', '10.1093/jcr/ucac029', 'Mostrar una racha intacta aumenta el compromiso. Al romperse, la gente abandona, sobre todo si se culpa a sí misma, y abandona menos si la racha se puede reparar (7 estudios)', 'Sí', 'Media'),
 ('F10', 'formacion', 'Kivetz, R., Urminsky, O. y Zheng, Y. (2006). The goal-gradient hypothesis resurrected: Purchase acceleration, illusionary goal progress, and customer retention. Journal of Marketing Research, 43(1), 39–58.', 'https://business.columbia.edu/faculty/research/goal-gradient-hypothesis-resurrected-purchase-acceleration-illusionary-goal', 'El esfuerzo aumenta conforme la persona se acerca a la meta, incluso cuando el avance es ilusorio (tarjeta de 12 sellos con 2 de regalo)', 'Sí (DOI sin confirmar)', 'Media'),
 ('F11', 'actividad', 'Bull, F. C. et al. (2020). World Health Organization 2020 guidelines on physical activity and sedentary behaviour. British Journal of Sports Medicine, 54(24), 1451–1462.', '10.1136/bjsports-2020-102955', 'Adultos: 150–300 min/semana moderada o 75–150 vigorosa; fuerza ≥ 2 días/semana; reducir el sedentarismo (no hay umbral cuantificado); "algo es mejor que nada"', 'Sí', 'Alta'),
 ('F12', 'actividad', 'Lee, D. H. et al. (2022). Long-term leisure-time physical activity intensity and all-cause and cause-specific mortality. Circulation, 146(7), 523–534.', '10.1161/CIRCULATIONAHA.121.058162', 'El beneficio es casi máximo con 300–600 min/semana moderada o 150–300 vigorosa. Más allá ya no aumenta, aunque tampoco hay daño (n ≈ 116,000; 30 años)', 'Sí', 'Alta'),
 ('F13', 'actividad', 'Arem, H. et al. (2015). Leisure time physical activity and mortality: A detailed pooled analysis of the dose-response relationship. JAMA Internal Medicine, 175(6), 959–967.', '10.1001/jamainternmed.2015.0533', 'El beneficio se estabiliza entre 3 y 5 veces el mínimo (22.5–37.5 MET-h/semana); sin riesgo extra a 10 veces', 'Sí', 'Alta'),
 ('F14', 'actividad', 'Momma, H. et al. (2022). Muscle-strengthening activities are associated with lower risk and mortality in major non-communicable diseases. British Journal of Sports Medicine, 56(13), 755–763.', 'https://pubmed.ncbi.nlm.nih.gov/35228201/', 'Curva en J: la máxima reducción de riesgo (≈ 10–20 %) está en 30–60 min/semana de fuerza; con más volumen, el beneficio es incierto', 'Sí', 'Baja–media (16 estudios)'),
 ('F15', 'actividad', 'Paluch, A. E. et al. (2022). Daily steps and all-cause mortality: A meta-analysis of 15 international cohorts. The Lancet Public Health, 7(3), e219–e228.', '10.1016/S2468-2667(21)00302-9', 'El beneficio se estabiliza en 6,000–8,000 pasos/día para personas de 60 años o más y en 8,000–10,000 para menores de 60', 'Sí', 'Alta'),
 ('F16', 'actividad', 'Garber, C. E. et al. (2011). Quantity and quality of exercise for developing and maintaining cardiorespiratory, musculoskeletal, and neuromotor fitness in apparently healthy adults (ACSM position stand). Medicine & Science in Sports & Exercise, 43(7), 1334–1359.', '10.1249/MSS.0b013e318213fefb', 'Flexibilidad: ejercicios para cada grupo muscular mayor, 60 s en total por ejercicio, ≥ 2 días/semana', 'Sí', 'Media'),
 ('F17', 'actividad', 'Dunstan, D. W. et al. (2012). Breaking up prolonged sitting reduces postprandial glucose and insulin responses. Diabetes Care, 35(5), 976–983.', 'https://pubmed.ncbi.nlm.nih.gov/22374636/', 'Caminar 2 min cada 20 min de estar sentado bajó la glucosa y la insulina después de comer', 'Sí', 'Baja–media (n = 19, efecto agudo)'),
 ('F18', 'salud', 'Watson, N. F. et al. (2015). Recommended amount of sleep for a healthy adult: A joint consensus statement of the AASM and SRS. Journal of Clinical Sleep Medicine, 11(6), 591–592.', 'https://pubmed.ncbi.nlm.nih.gov/25979105/', 'Adultos: ≥ 7 h. No es claro si más de 9 h es dañino (puede ser apropiado en jóvenes, en recuperación o en enfermedad)', 'Sí', 'Alta'),
 ('F19', 'salud', 'Hirshkowitz, M. et al. (2015). National Sleep Foundation''s sleep time duration recommendations: Methodology and results summary. Sleep Health, 1(1), 40–43.', '10.1016/j.sleh.2014.12.010', 'Adultos de 18–64 años: 7–9 h recomendado; de 6 o de 10–11 h "puede ser apropiado"; fuera de eso, no recomendado. Mayores de 65: 7–8 h', 'Sí', 'Alta'),
 ('F20', 'salud', 'EFSA Panel on Dietetic Products, Nutrition and Allergies (2010). Scientific opinion on dietary reference values for water. EFSA Journal, 8(3), 1459.', '10.2903/j.efsa.2010.1459', 'Agua total: 2.0 L/día en mujeres y 2.5 L/día en hombres; ≈ 70–80 % viene de las bebidas', 'Sí (DOI de memoria)', 'Alta'),
 ('F21', 'salud', 'Institute of Medicine / National Academies (2004). Dietary Reference Intakes for Water, Potassium, Sodium, Chloride, and Sulfate.', 'https://www.nationalacademies.org/news/report-sets-dietary-intake-levels-for-water-salt-and-potassium-to-maintain-health-and-reduce-chronic-disease-risk', 'Agua total: 2.7 L/día en mujeres y 3.7 L/día en hombres (medianas de población, no metas individuales)', 'Sí', 'Alta'),
 ('F22', 'salud', 'StatPearls: Water intoxication (NCBI Bookshelf NBK572128).', 'https://www.ncbi.nlm.nih.gov/books/NBK572128', 'En reposo, los riñones eliminan como máximo ≈ 0.8–1.0 L/h; beber más rápido es el principal factor de riesgo de hiponatremia', 'Sí', 'Media'),
 ('F23', 'salud', 'Organización Mundial de la Salud (2026). Healthy diet (hoja informativa).', 'https://www.who.int/news-room/fact-sheets/detail/healthy-diet', '≥ 400 g/día de frutas y verduras (sin tubérculos); azúcares libres < 10 % de la energía (≈ 50 g en 2,000 kcal), idealmente < 5 % (≈ 25 g)', 'Sí', 'Alta'),
 ('F24', 'salud', 'Aune, D. et al. (2017). Fruit and vegetable intake and the risk of cardiovascular disease, total cancer and all-cause mortality. International Journal of Epidemiology, 46(3), 1029–1056.', '10.1093/ije/dyw319', 'RR 0.90 por cada 200 g/día; el beneficio sigue hasta 800 g/día', 'Sí', 'Alta (observacional)'),
 ('F25', 'salud', 'Anderson, B. O. et al. (2023). Health and cancer risks associated with low levels of alcohol consumption. The Lancet Public Health, 8(1), e6–e7 · OMS Europa.', 'https://www.who.int/europe/news/item/04-01-2023-no-level-of-alcohol-consumption-is-safe-for-our-health', '"Ningún nivel de consumo de alcohol es seguro para la salud"', 'Sí', 'Alta en la dirección'),
 ('F26', 'salud', 'Canadian Centre on Substance Use and Addiction (2023). Canada''s Guidance on Alcohol and Health: Final Report.', 'https://ccsa.ca/canadas-guidance-alcohol-and-health-final-report', 'Riesgo por semana: 0 da beneficios; 1–2 bebidas estándar, bajo; 3–6, moderado; 7 o más, cada vez más alto', 'Sí', 'Media (umbrales modelados, en debate)'),
 ('F27', 'salud', 'Hackshaw, A. et al. (2018). Low cigarette consumption and risk of coronary heart disease and stroke: Meta-analysis of 141 cohort studies in 55 study reports. BMJ, 360, j5855.', '10.1136/bmj.j5855', 'Un cigarro al día equivale a ≈ 46 % (hombres) y 31 % (mujeres) del exceso de riesgo coronario de 20 al día. No hay nivel seguro; la meta es dejarlo', 'Sí', 'Alta'),
 ('F28', 'educacion', 'Bavishi, A., Slade, M. D. y Levy, B. R. (2016). A chapter a day: Association of book reading with longevity. Social Science & Medicine, 164, 44–48.', 'https://pmc.ncbi.nlm.nih.gov/articles/PMC5105607', 'Quienes leen libros tuvieron 20 % menos mortalidad en 12 años; hasta 3.5 h/semana, −17 %; más de 3.5 h, −23 % (n = 3,635, 50 años o más)', 'Sí', 'Baja–media (asociación)'),
 ('F29', 'educacion', 'Brysbaert, M. (2019). How many words do we read per minute? A review and meta-analysis of reading rate. Journal of Memory and Language, 109, 104047.', '10.1016/j.jml.2019.104047', 'Lectura silenciosa de adultos: 238 palabras/min en no ficción y 260 en ficción (190 estudios, n = 18,573). Sirve para convertir páginas a minutos', 'Sí', 'Alta (para la conversión)'),
 ('F30', 'educacion', 'Cepeda, N. J., Pashler, H., Vul, E., Wixted, J. T. y Rohrer, D. (2006). Distributed practice in verbal recall tasks. Psychological Bulletin, 132(3), 354–380. · Cepeda et al. (2008), Psychological Science, 19, 1095–1102.', '10.1037/0033-2909.132.3.354 · https://pubmed.ncbi.nlm.nih.gov/19076480/', 'Repartir la práctica es mejor que concentrarla; el intervalo óptimo crece con el tiempo que se quiere recordar (839 evaluaciones)', 'Sí', 'Alta'),
 ('F31', 'educacion', 'Ericsson, K. A., Krampe, R. T. y Tesch-Römer, C. (1993). The role of deliberate practice in the acquisition of expert performance. Psychological Review, 100(3), 363–406.', '10.1037/0033-295X.100.3.363', 'Los expertos sostienen ≈ 4 h/día de práctica deliberada como máximo; más allá, prácticamente no hay beneficio', 'Sí (referencia)', 'Media (en debate)'),
 ('F32', 'bienestar', 'Strohmaier, S. (2020). The relationship between doses of mindfulness-based programs and depression, anxiety, stress, and mindfulness: A dose-response meta-regression of randomized controlled trials. Mindfulness, 11, 1315–1335.', '10.1007/s12671-020-01319-4', 'En 203 ensayos, más práctica no mejoró la depresión, la ansiedad ni el estrés; solo hubo dosis-respuesta en el nivel de mindfulness', 'Sí', 'Media'),
 ('F33', 'bienestar', 'Britton, W. B. et al. (2021). Defining and measuring meditation-related adverse effects in mindfulness-based programs. Clinical Psychological Science, 9(6), 1185–1204.', 'https://pmc.ncbi.nlm.nih.gov/articles/PMC8636531', '58 % reportó al menos un efecto adverso; 37 % con impacto en su funcionamiento; 6 % duró más de un mes', 'Sí', 'Media'),
 ('F34', 'bienestar', 'Protocolo MBSR: UMass Memorial Health; StatPearls.', 'https://www.ummhealth.org/node/21859 · https://www.statpearls.com/point-of-care/144017', 'Práctica en casa de ≈ 45 min/día, 6 días por semana (UMass da 45–60)', 'Sí (fuentes secundarias)', 'Media'),
 ('F35', 'bienestar', 'Emmons, R. A. y McCullough, M. E. (2003). Counting blessings versus burdens. Journal of Personality and Social Psychology, 84(2), 377–389.', '10.1037/0022-3514.84.2.377', 'Escribir gratitud una vez por semana durante 10 semanas aumentó el bienestar', 'Sí', 'Media'),
 ('F36', 'bienestar', 'Lyubomirsky, S., Sheldon, K. M. y Schkade, D. (2005). Pursuing happiness: The architecture of sustainable change. Review of General Psychology, 9(2), 111–131.', '10.1037/1089-2680.9.2.111', 'Contar bendiciones una vez por semana funcionó mejor que tres veces (la repetición desgasta el efecto)', 'Sí', 'Baja (datos no publicados citados en la revisión)'),
 ('F37', 'bienestar', 'Hunt, M. G., Marx, R., Lipson, C. y Young, J. (2018). No more FOMO: Limiting social media decreases loneliness and depression. Journal of Social and Clinical Psychology, 37(10), 751–768. · Réplica: Bradley et al. (en prensa, Clinical Psychological Science), nota de la APS de 2026.', '10.1521/jscp.2018.37.10.751 · https://www.psychologicalscience.org/news/2026-aug-young-adults-social-media-well-being.html', 'Limitar a 30 min/día bajó la soledad y la depresión (n = 143), pero la réplica de 4 estudios no encontró beneficio con 30 ni con 60 min', 'Sí', 'Baja (resultado en disputa)'),
 ('F38', 'bienestar', 'Holt-Lunstad, J., Smith, T. B. y Layton, J. B. (2010). Social relationships and mortality risk: A meta-analytic review. PLoS Medicine, 7(7), e1000316.', '10.1371/journal.pmed.1000316', 'Los lazos sociales fuertes dan 50 % más probabilidad de sobrevivir (OR 1.50; 148 estudios). No establece una dosis', 'Sí', 'Alta (en la dirección)'),
 ('F39', 'bienestar', 'White, M. P. et al. (2019). Spending at least 120 minutes a week in nature is associated with good health and wellbeing. Scientific Reports, 9, 7730.', '10.1038/s41598-019-44097-3', 'Con ≥ 120 min/semana en la naturaleza aumenta la probabilidad de buena salud y bienestar; la asociación alcanza su máximo en 200–300 min, sin ganancia después (n = 19,806, transversal)', 'Sí', 'Media'),
 ('F40', 'color', 'Elliot, A. J. y Maier, M. A. (2014). Color psychology: Effects of perceiving color on psychological functioning in humans. Annual Review of Psychology, 65, 95–120.', 'https://pubmed.ncbi.nlm.nih.gov/23808916/', 'Campo "incipiente": efectos que dependen del contexto, la mayoría de la evidencia es sobre el rojo, y en contextos de logro el rojo se asocia con peligro o falla', 'Sí', 'Media'),
 ('F41', 'color', 'Jonauskaite, D. et al. (2020). Universal patterns in color-emotion associations are further shaped by linguistic and geographic proximity. Psychological Science, 31(10), 1245–1260.', '10.1177/0956797620948810', 'Las asociaciones color-emoción son en buena parte universales (r = .88; 4,598 personas; 30 países), con matices por país e idioma', 'Sí (solo el resumen; no se pudo leer la asociación de cada color)', 'Media'),
 ('F42', 'color', 'Valdez, P. y Mehrabian, A. (1994). Effects of color on emotions. Journal of Experimental Psychology: General, 123(4), 394–409.', 'https://pubmed.ncbi.nlm.nih.gov/7996122/', 'Placer = .69·brillo + .22·saturación; activación = −.31·brillo + .60·saturación. Los tonos más agradables: azul, azul-verde, verde y púrpura; los menos: amarillo y verde-amarillo', 'Sí', 'Media'),
 ('F43', 'color', 'Mehta, R. y Zhu, R. J. (2009). Blue or red? Exploring the effect of color on cognitive task performances. Science, 323(5918), 1226–1229.', 'https://pubmed.ncbi.nlm.nih.gov/19197022/', 'El rojo favoreció tareas de detalle (motivación de evitación) y el azul, tareas creativas (de acercamiento); las réplicas son mixtas', 'Sí', 'Baja–media'),
 ('F44', 'color', 'Kaya, N. y Epps, H. H. (2004). Relationship between color and emotion: A study of college students. College Student Journal, 38(3), 396–405.', 'https://www.scinapse.io/papers/53934299', 'El verde provocó el mayor porcentaje de emociones positivas (relajación, paz, esperanza); el amarillo, energía (n = 98)', 'Parcial (la cifra del verde viene de una fuente secundaria)', 'Baja'),
 ('F45', 'color', 'W3C (2023). Web Content Accessibility Guidelines (WCAG) 2.2, criterios 1.4.1, 1.4.3 y 1.4.11.', 'https://www.w3.org/TR/WCAG22/', 'Texto ≥ 4.5:1 (≥ 3:1 si es grande); componentes y gráficos ≥ 3:1; el color nunca es la única señal', 'Sí', 'Alta (norma)'),
 ('F46', 'notificaciones', 'Yancey, K. P. y Settles, B. (2020). A sleeping, recovering bandit algorithm for optimizing recurring notifications. KDD ''20.', 'https://research.duolingo.com/papers/yancey.kdd20.pdf', 'Duolingo elige la plantilla de cada aviso con un algoritmo de "bandido" que premia las plantillas no usadas recientemente (novedad) y mide el éxito como una lección hecha en las 2 h siguientes', 'Sí (no publica cifras de usuarios activos)', 'Media'),
 ('F47', 'notificaciones', 'Duolingo (blog de la empresa). How the Duolingo streak builds habit · How streaks keep Duolingo learners committed.', 'https://blog.duolingo.com/how-duolingo-streak-builds-habit · https://making.duolingo.com/how-streaks-keep-duolingo-learners-committed-to-their-language-goals', 'Racha de 7 días: 3.6 veces más probabilidad de terminar el curso. Hasta 2 "congelamientos": +0.38 % de activos diarios. Animación de hito: +1.7 % de retención al día 7', 'Sí', 'Baja–media (datos internos sin revisión por pares)'),
 ('F48', 'notificaciones', 'Stawarz, K., Cox, A. L. y Blandford, A. (2015). Beyond self-tracking and reminders: Designing smartphone apps that support habit formation. CHI ''15.', '10.1145/2702123.2702230', 'Los recordatorios ayudaron a repetir, pero estorbaron la automaticidad. Las señales de eventos ("después de lavarme los dientes…") la aumentaron. El refuerzo positivo no tuvo efecto', 'Sí', 'Media'),
 ('F49', 'notificaciones', 'Nahum-Shani, I. et al. (2018). Just-in-time adaptive interventions (JITAIs) in mobile health. Annals of Behavioral Medicine, 52(6), 446–462.', '10.1007/s12160-016-9830-8', 'Marco para intervenir solo en el momento oportuno según el estado de la persona, sin ofrecer apoyo innecesario ni interrumpir', 'Sí', 'Alta (marco)'),
 ('F50', 'notificaciones', 'Mehrotra, A., Pejovic, V., Vermeulen, J., Hendley, R. y Musolesi, M. (2016). My phone and me: Understanding people''s receptivity to mobile notifications. CHI ''16.', '10.1145/2858036.2858566', 'La receptividad a una notificación depende del contexto, del contenido y de la persona', 'Sí', 'Media'),
 ('F51', 'notificaciones', 'Google. Material Design 3: Navigation bar.', 'https://m3.material.io/components/navigation-bar/guidelines', 'La barra inferior lleva de 3 a 5 destinos', 'No (de memoria; verificar antes de citarla fuera de este documento)', 'Alta (guía)'),
 ('F52', 'formacion', 'Maltz, M. (1960). Psycho-Cybernetics. Prentice-Hall · Gardner, B. (2012). Busting the 21 days habit formation myth. UCL Health Behaviour Research Centre.', 'https://blogs.ucl.ac.uk/bsh/2012/06/29/busting-the-21-days-habit-formation-myth/', 'El origen del "21 días" es el tiempo que los pacientes de cirugía plástica tardaban en acostumbrarse a su cara; no es un dato sobre hábitos', 'Sí', 'Alta (que es un mito)'),
 ('F53', 'formacion', 'Michie, S., Abraham, C., Whittington, C., McAteer, J. y Gupta, S. (2009). Effective techniques in healthy eating and physical activity interventions: A meta-regression. Health Psychology, 28(6), 690–701.', '10.1037/a0016136 · https://pubmed.ncbi.nlm.nih.gov/19916637/', 'Las intervenciones que combinaron el automonitoreo con otra técnica de autorregulación tuvieron más efecto (d = 0.42 contra 0.26; 101 estudios, n = 44,747). Lo usamos para recomendar "Anotar tus gastos" en Finanzas: aplicarlo a las finanzas es una extrapolación', 'Sí (resumen en PubMed, 27-nov-2026)', 'Baja para finanzas (el estudio es de alimentación y actividad física)');

-- ¿Todas las claves F## de un texto existen? (para validar "F11, F14")
CREATE FUNCTION fn_fuentes_validas(p_fuentes text) RETURNS boolean
LANGUAGE sql STABLE
SET search_path = kaizen, pg_temp
AS $$
    SELECT p_fuentes IS NULL OR (
           p_fuentes ~ '^F[0-9]{2}(, F[0-9]{2})*$'
       AND NOT EXISTS (SELECT 1 FROM unnest(string_to_array(p_fuentes, ', ')) AS f(clave)
                        WHERE NOT EXISTS (SELECT 1 FROM fuente_cientifica c WHERE c.clave = f.clave)));
$$;

-- =====================================================================
-- 2. Hábitos recomendados
-- =====================================================================
CREATE TABLE habito_recomendado (
    id               uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
    clave            text          NOT NULL UNIQUE CHECK (clave ~ '^[a-z_0-9]{3,40}$'),
    subcategoria_id  uuid          NOT NULL,
    nombre           text          NOT NULL CHECK (length(nombre) BETWEEN 1 AND 60),
    unidad           text          NOT NULL,
    meta             numeric(10,2) NOT NULL CHECK (meta > 0),
    frecuencia_tipo  text          NOT NULL CHECK (frecuencia_tipo IN ('diaria', 'dias_semana', 'n_por_semana')),
    dias_semana      smallint      CHECK (dias_semana BETWEEN 1 AND 127),
    veces_semana     smallint      CHECK (veces_semana BETWEEN 1 AND 7),
    momento          text          NOT NULL CHECK (length(momento) BETWEEN 1 AND 120),   -- se vuelve la intención
    porque           text          NOT NULL CHECK (length(porque) BETWEEN 3 AND 300),    -- sin fuente: va en `fuentes`
    fuentes          text          NOT NULL CHECK (fuentes ~ '^F[0-9]{2}(, F[0-9]{2})*$'),
    orden            smallint      NOT NULL DEFAULT 99,
    activo           boolean       NOT NULL DEFAULT true,
    actualizado_en   timestamptz   NOT NULL DEFAULT now(),
    FOREIGN KEY (subcategoria_id, unidad) REFERENCES unidad_subcategoria (subcategoria_id, unidad),
    CONSTRAINT frecuencia_coherente CHECK (
           (frecuencia_tipo = 'diaria'       AND dias_semana IS NULL     AND veces_semana IS NULL)
        OR (frecuencia_tipo = 'dias_semana'  AND dias_semana IS NOT NULL AND veces_semana IS NULL)
        OR (frecuencia_tipo = 'n_por_semana' AND dias_semana IS NULL     AND veces_semana IS NOT NULL))
);
CREATE INDEX ix_habito_recomendado_sub ON habito_recomendado (subcategoria_id, orden);
COMMENT ON TABLE habito_recomendado IS
    'Hábitos saludables listos para crear (pantalla Nuevo hábito). Meta en el óptimo de la evidencia; el usuario solo elige prioridad y cápsula.';

-- El id sale de la clave (md5): es el mismo en el clúster, en el entorno local y en la demo de la app
INSERT INTO habito_recomendado (id, clave, subcategoria_id, nombre, unidad, meta, frecuencia_tipo, dias_semana,
                                veces_semana, momento, porque, fuentes, orden)
SELECT md5('kaizen-recomendacion:' || v.clave)::uuid, v.clave, s.id, v.nombre, v.unidad, v.meta, v.tipo, v.dias, v.veces, v.momento, v.porque, v.fuentes, v.orden
  FROM (VALUES
 ('caminar_rapido', 'aerobico_moderado', 'Caminar a paso rápido', 'min', 30, 'dias_semana', 31::smallint, NULL::smallint,
  'Después de comer',
  'La OMS recomienda de 150 a 300 minutos de actividad moderada a la semana. 30 minutos de lunes a viernes llegan a 150.', 'F11', 1),
 ('andar_bicicleta', 'aerobico_moderado', 'Andar en bicicleta', 'min', 50, 'dias_semana', 21::smallint, NULL::smallint,
  'Al salir del trabajo o la escuela',
  'Pedalear a ritmo moderado cuenta para los 150 a 300 minutos semanales: 3 salidas de 50 minutos dan 150.', 'F11', 2),
 ('bailar', 'aerobico_moderado', 'Bailar', 'min', 30, 'n_por_semana', NULL::smallint, 5::smallint,
  'Después de cenar',
  'Cualquier actividad que acelere tu respiración cuenta como moderada: 30 minutos 5 veces a la semana cumplen lo mínimo.', 'F11', 3),
 ('nadar', 'aerobico_moderado', 'Nadar', 'min', 45, 'n_por_semana', NULL::smallint, 4::smallint,
  'Por la mañana, antes de tus pendientes',
  'Nadar a ritmo tranquilo es actividad moderada: 45 minutos 4 veces a la semana dan 180, dentro de lo recomendado.', 'F11', 4),
 ('correr', 'vigoroso', 'Correr', 'min', 25, 'dias_semana', 21::smallint, NULL::smallint,
  'Al despertar',
  'En lugar de la actividad moderada, la OMS acepta de 75 a 150 minutos de actividad vigorosa a la semana.', 'F11', 1),
 ('intervalos', 'vigoroso', 'Entrenamiento por intervalos', 'min', 20, 'n_por_semana', NULL::smallint, 4::smallint,
  'Antes de bañarte',
  'Los intervalos intensos son actividad vigorosa: 20 minutos 4 veces a la semana pasan de los 75 recomendados.', 'F11', 2),
 ('deporte_equipo', 'vigoroso', 'Jugar fútbol o básquetbol', 'min', 50, 'n_por_semana', NULL::smallint, 2::smallint,
  'El fin de semana, con tu equipo',
  'Los deportes de equipo son actividad vigorosa: dos partidos de 50 minutos dan 100 a la semana.', 'F11', 3),
 ('fuerza_casa', 'fuerza', 'Ejercicios de fuerza en casa', 'min', 20, 'dias_semana', 9::smallint, NULL::smallint,
  'Después de caminar',
  'La OMS pide fortalecer los músculos al menos 2 días por semana; de 30 a 60 minutos semanales dan el mayor beneficio.', 'F11, F14', 1),
 ('levantar_pesas', 'fuerza', 'Levantar pesas', 'min', 25, 'dias_semana', 10::smallint, NULL::smallint,
  'Después del trabajo',
  'Dos sesiones de 25 minutos caen en los 30 a 60 minutos semanales con mayor beneficio.', 'F11, F14', 2),
 ('fuerza_ligas', 'fuerza', 'Fuerza con ligas', 'min', 15, 'dias_semana', 21::smallint, NULL::smallint,
  'Al despertar',
  'Tres sesiones cortas de 15 minutos suman 45 a la semana, dentro del rango con más beneficio.', 'F11, F14', 3),
 ('sentadillas_lagartijas', 'fuerza', 'Sentadillas y lagartijas', 'min', 10, 'n_por_semana', NULL::smallint, 3::smallint,
  'Antes de bañarte',
  'Aun 30 minutos de fuerza a la semana reducen el riesgo; repartirlos en 3 días te da tiempo de recuperarte.', 'F14', 4),
 ('pasos_8000', 'pasos', 'Caminar 8,000 pasos', 'pasos', 8000, 'diaria', NULL::smallint, NULL::smallint,
  'Durante el día, en traslados y pausas',
  'El beneficio de caminar crece hasta los 8,000 a 10,000 pasos al día (de 6,000 a 8,000 después de los 60).', 'F15', 1),
 ('pasos_10000', 'pasos', 'Caminar 10,000 pasos', 'pasos', 10000, 'diaria', NULL::smallint, NULL::smallint,
  'Con una caminata después de cenar',
  'Llegar a 10,000 pasos al día está en el rango donde el beneficio de caminar se estabiliza.', 'F15', 2),
 ('pasos_9000_semana', 'pasos', 'Caminar 9,000 pasos entre semana', 'pasos', 9000, 'dias_semana', 31::smallint, NULL::smallint,
  'Bajándote una parada antes o usando escaleras',
  'Entre 8,000 y 10,000 pasos al día es lo que más beneficio da antes de los 60 años.', 'F15', 3),
 ('estirar_despues', 'estiramiento', 'Estirar después de ejercitarte', 'min', 10, 'dias_semana', 21::smallint, NULL::smallint,
  'Después de ejercitarte',
  'Estirar los grupos musculares grandes al menos 2 o 3 días por semana mejora la flexibilidad.', 'F16', 1),
 ('estirar_manana', 'estiramiento', 'Estirar cada mañana', 'min', 10, 'diaria', NULL::smallint, NULL::smallint,
  'Al despertar',
  'Estirar a diario da más efecto que hacerlo solo 2 o 3 días por semana.', 'F16', 2),
 ('yoga_suave', 'estiramiento', 'Yoga suave', 'min', 20, 'dias_semana', 10::smallint, NULL::smallint,
  'Antes de dormir',
  'Las posturas sostenidas cuentan como estiramiento: 2 sesiones de 20 minutos dan 40 a la semana.', 'F16', 3),
 ('pausa_cada_hora', 'pausas_activas', 'Pausa activa cada hora', 'pausas', 8, 'dias_semana', 31::smallint, NULL::smallint,
  'Cada hora que pases sentado',
  'Levantarte un par de minutos cada cierto tiempo mejora tu glucosa después de comer.', 'F11, F17', 1),
 ('pausa_cada_30', 'pausas_activas', 'Pausa activa cada 30 minutos', 'pausas', 16, 'dias_semana', 31::smallint, NULL::smallint,
  'Con una alarma cada 30 minutos',
  'Interrumpir el tiempo sentado cada 20 a 30 minutos dio los mejores resultados en los estudios.', 'F17', 2),
 ('pausas_estudio', 'pausas_activas', 'Pausas al estudiar o trabajar', 'pausas', 10, 'diaria', NULL::smallint, NULL::smallint,
  'Al terminar cada bloque de trabajo',
  'Romper el tiempo sentado con pausas cortas reduce los efectos de estar quieto mucho tiempo.', 'F11, F17', 3),
 ('agua_8_vasos', 'hidratacion', 'Tomar 8 vasos de agua', 'vasos', 8, 'diaria', NULL::smallint, NULL::smallint,
  'Con cada comida y entre comidas',
  'De bebidas se recomiendan entre 1.5 y 3 litros al día: 8 vasos son 2 litros.', 'F20, F21', 1),
 ('agua_2_litros', 'hidratacion', 'Tomar 2 litros de agua', 'L', 2, 'diaria', NULL::smallint, NULL::smallint,
  'Con una botella siempre a la mano',
  'Dos litros de bebidas al día están en el centro de lo recomendado (de 1.5 a 3 litros).', 'F20, F21', 2),
 ('agua_1_5_litros', 'hidratacion', 'Tomar 1.5 litros de agua', 'L', 1.5, 'diaria', NULL::smallint, NULL::smallint,
  'Al despertar y con cada comida',
  'Litro y medio de bebidas al día es el mínimo recomendado.', 'F20', 3),
 ('agua_2500_ml', 'hidratacion', 'Tomar 2,500 ml de agua', 'ml', 2500, 'diaria', NULL::smallint, NULL::smallint,
  'En días de calor o de ejercicio',
  'Con calor o ejercicio conviene ir hacia lo alto del rango, sin pasar de 3 litros de bebidas al día.', 'F20, F21', 4),
 ('dormir_7', 'sueno', 'Dormir 7 horas', 'h', 7, 'diaria', NULL::smallint, NULL::smallint,
  'A la misma hora cada noche',
  'Los adultos necesitan dormir al menos 7 horas por noche.', 'F18', 1),
 ('dormir_8', 'sueno', 'Dormir 8 horas', 'h', 8, 'diaria', NULL::smallint, NULL::smallint,
  'Después de apagar las pantallas',
  'Entre 7 y 9 horas por noche es lo recomendado para adultos.', 'F18, F19', 2),
 ('dormir_7_5', 'sueno', 'Dormir 7.5 horas', 'h', 7.5, 'diaria', NULL::smallint, NULL::smallint,
  'Acostándote a la misma hora, también el fin de semana',
  'Un horario regular ayuda a dormir lo recomendado: de 7 a 9 horas.', 'F18, F19', 3),
 ('dormir_8_5', 'sueno', 'Dormir 8.5 horas', 'h', 8.5, 'diaria', NULL::smallint, NULL::smallint,
  'Si sueles despertar cansado',
  'Si despiertas cansado, acercarte a 9 horas sigue dentro de lo recomendado.', 'F19', 4),
 ('frutas_5', 'frutas_verduras', 'Comer 5 porciones de frutas y verduras', 'porciones', 5, 'diaria', NULL::smallint, NULL::smallint,
  'En cada comida',
  'Se recomiendan al menos 400 g al día: 5 porciones de 80 g.', 'F23', 1),
 ('frutas_400g', 'frutas_verduras', 'Comer 400 g de frutas y verduras', 'g', 400, 'diaria', NULL::smallint, NULL::smallint,
  'Midiendo tus porciones al servir',
  'Al menos 400 g de frutas y verduras al día es lo mínimo recomendado.', 'F23', 2),
 ('frutas_7', 'frutas_verduras', 'Comer 7 porciones de frutas y verduras', 'porciones', 7, 'diaria', NULL::smallint, NULL::smallint,
  'Agregando verdura a la comida y a la cena',
  'El beneficio sigue aumentando hasta unos 800 g al día (10 porciones).', 'F23, F24', 3),
 ('verdura_cada_comida', 'frutas_verduras', 'Verdura en cada comida', 'porciones', 6, 'diaria', NULL::smallint, NULL::smallint,
  'Al servir tu plato',
  'Llenar parte del plato con verdura ayuda a llegar a 5 porciones o más al día.', 'F23, F24', 4),
 ('azucar_25g', 'reducir_azucar', 'Limitar el azúcar a 25 g', 'g', 25, 'diaria', NULL::smallint, NULL::smallint,
  'Al elegir bebidas y postres',
  'Lo ideal es menos de 25 g de azúcar libre al día, y nunca más de 50 g.', 'F23', 1),
 ('azucar_6_cucharaditas', 'reducir_azucar', 'Máximo 6 cucharaditas de azúcar', 'cucharaditas', 6, 'diaria', NULL::smallint, NULL::smallint,
  'Al endulzar café o té',
  'Seis cucharaditas son unos 24 g: debajo del ideal de 25 g de azúcar libre al día.', 'F23', 2),
 ('sin_refrescos', 'reducir_azucar', 'Cambiar el refresco por agua', 'g', 15, 'diaria', NULL::smallint, NULL::smallint,
  'En cada comida, con agua natural',
  'Las bebidas azucaradas son de las principales fuentes de azúcar libre; dejarlas te ayuda a quedarte debajo de 25 g.', 'F23', 3),
 ('alcohol_2', 'reducir_alcohol', 'Máximo 2 bebidas alcohólicas a la semana', 'bebidas', 2, 'n_por_semana', NULL::smallint, 1::smallint,
  'El fin de semana, contando cada bebida',
  'Ningún nivel de alcohol es seguro; de 1 a 2 bebidas a la semana es riesgo bajo.', 'F25, F26', 1),
 ('alcohol_1', 'reducir_alcohol', 'Máximo 1 bebida alcohólica a la semana', 'bebidas', 1, 'n_por_semana', NULL::smallint, 1::smallint,
  'En reuniones, alternando con agua',
  'Entre menos alcohol, mejor: una bebida a la semana mantiene el riesgo bajo.', 'F25, F26', 2),
 ('alcohol_solo_sabado', 'reducir_alcohol', 'Una bebida como máximo, solo el sábado', 'bebidas', 1, 'dias_semana', 32::smallint, NULL::smallint,
  'Si sales el sábado',
  'Ningún nivel es seguro: ponerte un tope claro te ayuda a no pasar de 2 bebidas a la semana.', 'F25, F26', 3),
 ('fumar_5', 'dejar_fumar', 'Bajar a 5 cigarros al día', 'cigarros', 5, 'diaria', NULL::smallint, NULL::smallint,
  'Retrasando el primero de la mañana',
  'No hay un nivel seguro: un cigarro al día conserva buena parte del riesgo. La Escalera te ayuda a bajar poco a poco hasta dejarlo.', 'F27', 1),
 ('fumar_1', 'dejar_fumar', 'Bajar a 1 cigarro al día', 'cigarros', 1, 'diaria', NULL::smallint, NULL::smallint,
  'Solo después de comer',
  'Bajar a uno es un gran paso, pero no hay nivel seguro: el siguiente es dejarlo.', 'F27', 2),
 ('leer_30', 'lectura', 'Leer 30 minutos', 'min', 30, 'diaria', NULL::smallint, NULL::smallint,
  'Antes de dormir',
  'Leer al menos 3.5 horas a la semana (30 minutos al día) se asoció con vivir más años.', 'F28', 1),
 ('leer_45', 'lectura', 'Leer 45 minutos', 'min', 45, 'diaria', NULL::smallint, NULL::smallint,
  'Durante tus traslados',
  'Entre 30 y 60 minutos al día está dentro de lo recomendado.', 'F28', 2),
 ('leer_60', 'lectura', 'Leer una hora', 'min', 60, 'diaria', NULL::smallint, NULL::smallint,
  'Después de cenar',
  'Hasta una hora al día sigue dentro de lo recomendado; leer más no hace daño.', 'F28', 3),
 ('leer_24_paginas', 'lectura', 'Leer 24 páginas', 'páginas', 24, 'diaria', NULL::smallint, NULL::smallint,
  'Antes de dormir',
  '24 páginas al día equivalen a unos 30 minutos de lectura.', 'F28, F29', 4),
 ('leer_30_paginas', 'lectura', 'Leer 30 páginas', 'páginas', 30, 'diaria', NULL::smallint, NULL::smallint,
  'Después de desayunar',
  '30 páginas al día son unos 37 minutos de lectura, dentro de lo recomendado.', 'F28, F29', 5),
 ('lectura_fin_semana', 'lectura', 'Lectura larga de fin de semana', 'min', 105, 'dias_semana', 96::smallint, NULL::smallint,
  'Sábado y domingo por la mañana',
  'Puedes llegar a las 3.5 horas semanales en dos sesiones largas.', 'F28', 6),
 ('leer_entre_semana', 'lectura', 'Leer 45 minutos entre semana', 'min', 45, 'dias_semana', 31::smallint, NULL::smallint,
  'Al llegar a casa',
  '45 minutos de lunes a viernes suman 225 a la semana, dentro de lo recomendado.', 'F28', 7),
 ('estudiar_bloques', 'estudio', 'Estudiar en bloques', 'min', 60, 'dias_semana', 31::smallint, NULL::smallint,
  'Después de comer, en bloques de 25 minutos con pausas',
  'Repartir el estudio en varias sesiones rinde más que estudiar todo de corrido.', 'F30', 1),
 ('repasar', 'estudio', 'Repasar lo aprendido', 'min', 30, 'dias_semana', 21::smallint, NULL::smallint,
  'Al día siguiente de cada clase',
  'Repasar en días distintos fija mejor lo aprendido que repasarlo todo de una vez.', 'F30', 2),
 ('estudiar_2h', 'estudio', 'Estudiar 2 horas', 'h', 2, 'dias_semana', 31::smallint, NULL::smallint,
  'En tu horario de mayor concentración',
  'Hasta unas 4 horas al día de práctica concentrada se pueden sostener; 2 horas dejan margen para descansar.', 'F31', 3),
 ('estudiar_lugar_fijo', 'estudio', 'Estudiar 90 minutos en un lugar fijo', 'min', 90, 'n_por_semana', NULL::smallint, 4::smallint,
  'En la biblioteca o en tu escritorio',
  'Estudiar siempre en el mismo lugar ayuda a que el contexto dispare el hábito.', 'F03, F30', 4),
 ('ejercicios_practica', 'estudio', 'Resolver ejercicios de práctica', 'min', 45, 'dias_semana', 42::smallint, NULL::smallint,
  'Después de clase',
  'Practicar en días separados fija mejor lo aprendido que hacerlo todo junto.', 'F30', 5),
 ('preparar_examenes', 'estudio', 'Preparar exámenes con anticipación', 'min', 40, 'diaria', NULL::smallint, NULL::smallint,
  'Desde dos semanas antes del examen',
  'Estudiar un poco cada día durante varias semanas rinde más que estudiar todo la noche anterior.', 'F30', 6),
 ('practica_deliberada', 'estudio', 'Práctica deliberada de una habilidad', 'min', 60, 'dias_semana', 31::smallint, NULL::smallint,
  'A la misma hora cada día',
  'La práctica concentrada y sostenida es lo que más mejora una habilidad; el máximo sostenible ronda 4 horas al día.', 'F31', 7),
 ('idioma_15', 'idiomas', 'Practicar un idioma 15 minutos', 'min', 15, 'diaria', NULL::smallint, NULL::smallint,
  'Después de desayunar',
  'Practicar poco y seguido aprovecha la práctica espaciada.', 'F30', 1),
 ('idioma_30', 'idiomas', 'Practicar un idioma 30 minutos', 'min', 30, 'dias_semana', 31::smallint, NULL::smallint,
  'En tus traslados',
  'Sesiones de 15 a 60 minutos, repartidas en la semana, aprovechan la práctica espaciada.', 'F30', 2),
 ('repasar_vocabulario', 'idiomas', 'Repasar vocabulario', 'min', 15, 'diaria', NULL::smallint, NULL::smallint,
  'Antes de dormir',
  'Repasar las palabras en días distintos las fija mejor que estudiarlas de una vez.', 'F30', 3),
 ('conversar_idioma', 'idiomas', 'Conversar en otro idioma', 'min', 30, 'n_por_semana', NULL::smallint, 2::smallint,
  'Con un compañero o un grupo',
  'Practicar hablando en sesiones espaciadas complementa el estudio diario.', 'F30', 4),
 ('escuchar_idioma', 'idiomas', 'Escuchar contenido en otro idioma', 'min', 20, 'diaria', NULL::smallint, NULL::smallint,
  'Mientras caminas o haces quehaceres',
  'Exponerte un poco cada día aprovecha la práctica espaciada.', 'F30', 5),
 ('clase_idioma', 'idiomas', 'Clase o lección de idioma', 'min', 45, 'dias_semana', 21::smallint, NULL::smallint,
  'A la misma hora, tres veces por semana',
  'Un horario fijo ayuda a que el hábito se dispare solo, y repartir las clases rinde más.', 'F03, F30', 6),
 ('meditar_10', 'meditacion', 'Meditar 10 minutos', 'min', 10, 'diaria', NULL::smallint, NULL::smallint,
  'Al despertar',
  'Sesiones breves de 10 a 20 minutos bastan; practicar más no mejoró más los resultados.', 'F32', 1),
 ('meditar_20', 'meditacion', 'Meditar 20 minutos', 'min', 20, 'diaria', NULL::smallint, NULL::smallint,
  'Antes de dormir',
  'Hasta 20 minutos al día está dentro de lo recomendado.', 'F32', 2),
 ('respiracion_consciente', 'meditacion', 'Respiración consciente', 'min', 10, 'dias_semana', 31::smallint, NULL::smallint,
  'En tu pausa del mediodía',
  'Una práctica breve entre semana es suficiente para notar el efecto.', 'F32', 3),
 ('meditacion_guiada', 'meditacion', 'Meditación guiada', 'min', 15, 'diaria', NULL::smallint, NULL::smallint,
  'Después de lavarte los dientes en la noche',
  'Entre 10 y 20 minutos al día es lo recomendado.', 'F32', 4),
 ('gratitud_semanal', 'gratitud', 'Escribir 3 cosas que agradeces', 'registros', 1, 'n_por_semana', NULL::smallint, 1::smallint,
  'El domingo en la noche',
  'Hacerlo una vez por semana funcionó mejor que tres: la repetición desgasta el efecto.', 'F36', 1),
 ('mensaje_gratitud', 'gratitud', 'Enviar un mensaje de agradecimiento', 'registros', 1, 'n_por_semana', NULL::smallint, 1::smallint,
  'Al final de la semana',
  'Expresar gratitud de forma regular mejoró el bienestar en los estudios.', 'F35', 2),
 ('diario_gratitud', 'gratitud', 'Diario de gratitud', 'registros', 1, 'dias_semana', 18::smallint, NULL::smallint,
  'Antes de dormir, martes y viernes',
  'Una o pocas veces por semana basta para notar el efecto.', 'F35, F36', 3),
 ('lo_bueno_semana', 'gratitud', 'Repasar lo bueno de la semana', 'registros', 1, 'dias_semana', 64::smallint, NULL::smallint,
  'El domingo después de cenar',
  'Detenerte a notar lo bueno una vez por semana mejoró el bienestar.', 'F35', 4),
 ('redes_2h', 'reducir_pantallas', 'Limitar redes sociales a 2 horas', 'h', 2, 'diaria', NULL::smallint, NULL::smallint,
  'Activando el límite de tu teléfono',
  'No hay un número con evidencia firme: ponerte un límite y bajarlo poco a poco con la Escalera es un buen inicio.', 'F37', 1),
 ('pantallas_noche', 'reducir_pantallas', 'Limitar pantallas en la noche a 30 minutos', 'min', 30, 'diaria', NULL::smallint, NULL::smallint,
  'Después de cenar',
  'Usar menos el teléfono por la noche te ayuda a acostarte a tiempo para dormir 7 horas o más.', 'F37, F18', 2),
 ('redes_1h', 'reducir_pantallas', 'Limitar redes sociales a 1 hora', 'h', 1, 'diaria', NULL::smallint, NULL::smallint,
  'Silenciando las notificaciones',
  'Un límite claro ayuda a usarlas con intención; la Escalera lo ajusta poco a poco.', 'F37', 3),
 ('pantalla_libre_3h', 'reducir_pantallas', 'Limitar el tiempo libre de pantalla a 3 horas', 'h', 3, 'diaria', NULL::smallint, NULL::smallint,
  'Revisando tu tiempo de uso cada noche',
  'Medir tu tiempo de pantalla es el primer paso para reducirlo poco a poco.', 'F37', 4),
 ('llamar_alguien', 'convivencia_social', 'Llamar a un familiar o amigo', 'veces', 1, 'n_por_semana', NULL::smallint, 3::smallint,
  'Después de cenar',
  'Las relaciones sociales tienen un efecto grande en la salud y en vivir más años.', 'F38', 1),
 ('comer_acompanado', 'convivencia_social', 'Comer acompañado', 'veces', 1, 'n_por_semana', NULL::smallint, 3::smallint,
  'En la comida o la cena',
  'Compartir tiempo con otros fortalece los lazos que protegen tu salud.', 'F38', 2),
 ('ver_amigos', 'convivencia_social', 'Ver a tus amigos', 'veces', 1, 'n_por_semana', NULL::smallint, 1::smallint,
  'El fin de semana',
  'Los lazos sociales fuertes se asocian con vivir más años.', 'F38', 3),
 ('tiempo_calidad', 'convivencia_social', 'Tiempo de calidad con alguien', 'min', 60, 'n_por_semana', NULL::smallint, 2::smallint,
  'Sin el teléfono a la mano',
  'Dedicar tiempo a las personas cercanas protege tu salud a largo plazo.', 'F38', 4),
 ('naturaleza_30', 'aire_libre', 'Tiempo en la naturaleza', 'min', 30, 'n_por_semana', NULL::smallint, 4::smallint,
  'Después del trabajo o la escuela',
  'Al menos 120 minutos a la semana en la naturaleza se asocian con mejor salud y bienestar.', 'F39', 1),
 ('paseo_domingo', 'aire_libre', 'Paseo largo al aire libre', 'min', 120, 'dias_semana', 64::smallint, NULL::smallint,
  'El domingo por la mañana',
  'Los 120 minutos semanales se pueden juntar en una sola salida.', 'F39', 2),
 ('caminar_parque', 'aire_libre', 'Caminar en un parque', 'min', 40, 'dias_semana', 21::smallint, NULL::smallint,
  'A la hora de la comida',
  'Tres caminatas de 40 minutos en un parque suman los 120 minutos recomendados.', 'F39', 3),
 ('hora_aire_libre', 'aire_libre', 'Una hora al aire libre', 'min', 60, 'n_por_semana', NULL::smallint, 3::smallint,
  'Al salir de clases o del trabajo',
  'El beneficio llega a su máximo entre 200 y 300 minutos a la semana.', 'F39', 4),
 ('ahorro_50_semana', 'ahorro', 'Apartar 50 pesos a la semana', 'pesos', 50, 'n_por_semana', NULL::smallint, 1::smallint,
  'El día que recibes tu pago',
  'Una meta concreta y un momento fijo ayudan a cumplirla; el monto lo ajustas con la Escalera.', 'F06, F04', 1),
 ('ahorro_100_semana', 'ahorro', 'Apartar 100 pesos a la semana', 'pesos', 100, 'n_por_semana', NULL::smallint, 1::smallint,
  'Antes de gastar en otra cosa',
  'Apartar primero y gastar después convierte el ahorro en un plan concreto.', 'F06, F04', 2),
 ('ahorro_20_diario', 'ahorro', 'Ahorrar 20 pesos al día', 'pesos', 20, 'diaria', NULL::smallint, NULL::smallint,
  'Al llegar a casa, en una alcancía',
  'Hacerlo a la misma hora y en el mismo lugar ayuda a que se vuelva automático.', 'F03, F06', 3),
 ('guardar_monedas', 'ahorro', 'Guardar las monedas del día', 'pesos', 10, 'diaria', NULL::smallint, NULL::smallint,
  'Al vaciar tus bolsillos en la noche',
  'Asociar el ahorro a algo que ya haces cada noche lo vuelve un hábito.', 'F03, F04', 4),
 ('ahorro_200_semana', 'ahorro', 'Ahorrar 200 pesos a la semana', 'pesos', 200, 'n_por_semana', NULL::smallint, 1::smallint,
  'Con una transferencia automática el día de pago',
  'Decidir de antemano cuándo y cuánto ahorrar ayuda a cumplirlo.', 'F04, F06', 5),
 ('ahorro_antojo', 'ahorro', 'Ahorrar lo de un antojo', 'pesos', 30, 'n_por_semana', NULL::smallint, 3::smallint,
  'Cuando decidas no comprar algo que no planeabas',
  'Un plan "si pasa esto, haré aquello" convierte la tentación en ahorro.', 'F04', 6),
 ('ahorro_entre_semana', 'ahorro', 'Ahorrar 30 pesos entre semana', 'pesos', 30, 'dias_semana', 31::smallint, NULL::smallint,
  'Al terminar tu jornada',
  'Una meta pequeña y concreta es más fácil de sostener.', 'F06', 7),
 ('fondo_emergencias', 'ahorro', 'Fondo de emergencias', 'pesos', 150, 'n_por_semana', NULL::smallint, 1::smallint,
  'Cada lunes, antes de planear la semana',
  'Una meta específica rinde más que "ahorrar lo que se pueda".', 'F06, F04', 8),
 ('ahorro_meta', 'ahorro', 'Ahorrar para una meta', 'pesos', 100, 'n_por_semana', NULL::smallint, 2::smallint,
  'Después de recibir cualquier ingreso',
  'Ponerle nombre y monto a lo que quieres lograr te ayuda a cumplirlo.', 'F06', 9),
 ('ahorro_cambio', 'ahorro', 'Ahorrar el cambio de tus compras', 'pesos', 20, 'n_por_semana', NULL::smallint, 3::smallint,
  'Después de pagar en efectivo',
  'Asociar el ahorro a un momento que ya ocurre ayuda a que se vuelva automático.', 'F03, F04', 10),
 ('anotar_gastos', 'control_gastos', 'Anotar tus gastos del día', 'registros', 1, 'diaria', NULL::smallint, NULL::smallint,
  'Antes de dormir',
  'Llevar un registro de lo que haces es de las técnicas de cambio de conducta con más efecto.', 'F53', 1),
 ('revisar_gastos_semana', 'control_gastos', 'Revisar tus gastos de la semana', 'registros', 1, 'dias_semana', 64::smallint, NULL::smallint,
  'El domingo en la tarde',
  'Revisar lo registrado y compararlo con tu meta ayuda a ajustar a tiempo.', 'F53, F06', 2),
 ('anotar_compras_pequenas', 'control_gastos', 'Anotar cada compra pequeña', 'veces', 1, 'diaria', NULL::smallint, NULL::smallint,
  'En cuanto pagues',
  'Registrar al momento hace visibles los gastos que se escapan.', 'F53', 3),
 ('presupuesto_semana', 'control_gastos', 'Hacer el presupuesto de la semana', 'registros', 1, 'dias_semana', 1::smallint, NULL::smallint,
  'El lunes por la mañana',
  'Un plan con montos concretos rinde más que "gastar menos".', 'F06, F53', 4),
 ('comparar_precios', 'control_gastos', 'Comparar precios antes de comprar', 'veces', 1, 'n_por_semana', NULL::smallint, 3::smallint,
  'Antes de cada compra grande',
  'Decidir de antemano qué harás en una situación ayuda a cumplirlo.', 'F04', 5),
 ('lista_super', 'control_gastos', 'Ir al súper con lista', 'veces', 1, 'n_por_semana', NULL::smallint, 1::smallint,
  'Antes de salir de casa',
  'Un plan concreto antes de comprar evita gastos que no tenías previstos.', 'F04, F06', 6),
 ('revisar_estado_cuenta', 'control_gastos', 'Revisar tu estado de cuenta', 'registros', 1, 'n_por_semana', NULL::smallint, 1::smallint,
  'El día que llega tu estado de cuenta',
  'Revisar lo que ya pasó es una forma de automonitoreo, de las técnicas con más efecto.', 'F53', 7),
 ('esperar_24h', 'control_gastos', 'Esperar 24 horas antes de una compra no planeada', 'veces', 1, 'n_por_semana', NULL::smallint, 2::smallint,
  'Cuando quieras comprar algo que no planeabas',
  'Un plan "si quiero comprar algo, espero un día" te ayuda a decidir con calma.', 'F04', 8),
 ('ingresos_y_gastos', 'control_gastos', 'Anotar tus ingresos y gastos', 'registros', 2, 'diaria', NULL::smallint, NULL::smallint,
  'En la noche, en tu app o libreta',
  'Registrar lo que entra y lo que sale te da una foto completa para decidir.', 'F53', 9),
 ('planear_comidas', 'control_gastos', 'Planear las comidas de la semana', 'veces', 1, 'dias_semana', 64::smallint, NULL::smallint,
  'El domingo, antes de ir al súper',
  'Planear con anticipación evita compras de último momento.', 'F04, F06', 10)
  ) AS v(clave, sub, nombre, unidad, meta, tipo, dias, veces, momento, porque, fuentes, orden)
  JOIN subcategoria s ON s.clave = v.sub;

-- La meta de cada recomendación respeta el rango de captura de su unidad
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM habito_recomendado r
                 JOIN unidad_subcategoria u ON u.subcategoria_id = r.subcategoria_id AND u.unidad = r.unidad
                WHERE r.meta NOT BETWEEN u.minimo AND u.maximo) THEN
        RAISE EXCEPTION 'Una recomendación tiene la meta fuera del rango de su unidad';
    END IF;
END $$;

-- Recomendaciones activas con su categoría y su evaluación (lo que lee la API)
CREATE VIEW v_habito_recomendado WITH (security_invoker = true) AS
SELECT r.id, r.clave, r.nombre, r.unidad, r.meta, r.frecuencia_tipo, r.dias_semana, r.veces_semana,
       r.momento, r.porque, r.fuentes, r.orden,
       c.id AS categoria_id, c.clave AS categoria_clave, c.nombre AS categoria_nombre, c.color AS categoria_color,
       c.icono AS categoria_icono, c.orden AS categoria_orden,
       s.id AS subcategoria_id, s.clave AS subcategoria_clave, s.nombre AS subcategoria_nombre,
       s.icono AS subcategoria_icono, s.sentido, s.orden AS subcategoria_orden,
       e.zona, e.optimo_desde, e.optimo_hasta, e.maximo
  FROM habito_recomendado r
  JOIN subcategoria s ON s.id = r.subcategoria_id AND s.activa
  JOIN categoria c    ON c.id = s.categoria_id AND c.activa
 CROSS JOIN LATERAL fn_evaluar_meta(r.subcategoria_id, r.unidad, r.meta, r.frecuencia_tipo,
                                    r.dias_semana, r.veces_semana) e
 WHERE r.activo;

-- =====================================================================
-- 3. Crear un hábito desde una recomendación
-- =====================================================================
ALTER TABLE habito ADD COLUMN recomendacion_id uuid REFERENCES habito_recomendado (id);
COMMENT ON COLUMN habito.recomendacion_id IS
    'Recomendación de la que salió el hábito (NULL = personalizado). No cambia después de crearlo.';

-- Se llama "0_" para correr ANTES de trg_habito_a_subcategoria (los BEFORE van en orden
-- alfabético): copia los datos de la recomendación y deja que la guardia los valide.
CREATE FUNCTION tg_habito_recomendacion() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
DECLARE
    r record;
BEGIN
    IF TG_OP = 'UPDATE' THEN
        IF NEW.recomendacion_id IS DISTINCT FROM OLD.recomendacion_id THEN
            RAISE EXCEPTION 'La recomendación de origen no se puede cambiar' USING ERRCODE = 'KZ011';
        END IF;
        RETURN NEW;
    END IF;
    IF NEW.recomendacion_id IS NULL THEN
        RETURN NEW;
    END IF;
    SELECT x.* INTO r
      FROM habito_recomendado x
      JOIN subcategoria s ON s.id = x.subcategoria_id AND s.activa
     WHERE x.id = NEW.recomendacion_id AND x.activo;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'La recomendación no está disponible' USING ERRCODE = 'KZ018';
    END IF;
    NEW.subcategoria_id := r.subcategoria_id;
    NEW.categoria_id    := NULL;                 -- la fija trg_habito_a_subcategoria
    NEW.nombre          := r.nombre;
    NEW.unidad          := r.unidad;
    NEW.meta            := r.meta;
    NEW.frecuencia_tipo := r.frecuencia_tipo;
    NEW.dias_semana     := r.dias_semana;
    NEW.veces_semana    := r.veces_semana;
    NEW.intencion       := r.momento;
    RETURN NEW;
END;
$$;
CREATE TRIGGER trg_habito_0_recomendacion BEFORE INSERT OR UPDATE OF recomendacion_id ON habito
    FOR EACH ROW EXECUTE FUNCTION tg_habito_recomendacion();

-- "Plan si-entonces" premia escribir tu propia intención: la que trae una recomendación no cuenta
DROP TRIGGER trg_habito_logro_intencion_ins ON habito;
CREATE TRIGGER trg_habito_logro_intencion_ins AFTER INSERT ON habito
    FOR EACH ROW WHEN (NEW.intencion IS NOT NULL AND NEW.recomendacion_id IS NULL)
    EXECUTE FUNCTION tg_habito_logro_intencion();

-- =====================================================================
-- 4. Días protegidos (escudo en el calendario)
-- Mismo recorrido que fn_rachas; devuelve cada día fallado que el protector
-- perdonó entre p_desde y p_hasta. Los días sin registro cuentan como fallados
-- hasta ayer (hoy todavía se puede hacer).
-- =====================================================================
CREATE FUNCTION fn_dias_protegidos(p_region region_t, p_habito uuid, p_desde date, p_hasta date)
RETURNS SETOF date
LANGUAGE plpgsql STABLE
SET search_path = kaizen, pg_temp
AS $$
DECLARE
    h         record;
    d         record;
    v_ini     date;
    v_fin     date;
    v_semana  date;
    v_racha   integer := 0;
BEGIN
    SELECT frecuencia_tipo, dias_semana INTO h FROM habito WHERE region = p_region AND id = p_habito;
    IF NOT FOUND THEN
        RETURN;
    END IF;
    SELECT min(fecha), max(fecha) INTO v_ini, v_fin
      FROM registro WHERE region = p_region AND habito_id = p_habito AND fecha <= p_hasta;
    IF v_ini IS NULL THEN
        RETURN;
    END IF;
    v_fin := greatest(v_fin, least(p_hasta, current_date - 1));

    FOR d IN
        SELECT s.dia::date AS dia, r.cumplido
          FROM generate_series(v_ini, v_fin, interval '1 day') AS s(dia)
          LEFT JOIN registro r
                 ON r.region = p_region AND r.habito_id = p_habito AND r.fecha = s.dia::date
         ORDER BY s.dia
    LOOP
        IF h.frecuencia_tipo = 'n_por_semana' THEN
            CONTINUE WHEN d.cumplido IS NULL;
        ELSIF NOT fn_dia_programado(h.frecuencia_tipo, h.dias_semana, d.dia) THEN
            CONTINUE;
        END IF;

        IF coalesce(d.cumplido, false) THEN
            v_racha := v_racha + 1;
        ELSIF v_racha > 0 AND v_semana IS DISTINCT FROM date_trunc('week', d.dia)::date THEN
            v_semana := date_trunc('week', d.dia)::date;
            IF d.dia >= p_desde THEN
                RETURN NEXT d.dia;
            END IF;
        ELSE
            v_racha := 0;
        END IF;
    END LOOP;
END;
$$;
COMMENT ON FUNCTION fn_dias_protegidos(region_t, uuid, date, date) IS
    'Días que perdonó el protector de racha (misma regla que fn_rachas). Para el escudo del calendario.';

-- =====================================================================
-- 5. Administración de las recomendaciones
-- =====================================================================
CREATE PROCEDURE sp_admin_guardar_recomendacion(
    p_admin            uuid,
    p_clave            text,
    p_subcategoria     uuid,
    p_nombre           text,
    p_unidad           text,
    p_meta             numeric,
    p_frecuencia_tipo  text,
    p_dias_semana      smallint,
    p_veces_semana     smallint,
    p_momento          text,
    p_porque           text,
    p_fuentes          text,
    p_activo           boolean DEFAULT true,
    p_orden            smallint DEFAULT 99,
    p_ip               inet DEFAULT NULL,
    INOUT p_id         uuid DEFAULT NULL)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
DECLARE
    v_region_admin region_t := fn_verificar_admin(p_admin);
    u record;
BEGIN
    SELECT minimo, maximo INTO u FROM unidad_subcategoria WHERE subcategoria_id = p_subcategoria AND unidad = p_unidad;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'La unidad "%" no está permitida para esta subcategoría', p_unidad USING ERRCODE = 'KZ016';
    END IF;
    IF p_meta IS NULL OR p_meta NOT BETWEEN u.minimo AND u.maximo THEN
        RAISE EXCEPTION 'La meta debe estar entre % y % %', u.minimo, u.maximo, p_unidad USING ERRCODE = 'KZ011';
    END IF;
    IF NOT fn_fuentes_validas(p_fuentes) OR p_fuentes IS NULL THEN
        RAISE EXCEPTION 'Las fuentes deben ser claves F## que existan' USING ERRCODE = 'KZ011';
    END IF;
    BEGIN
        INSERT INTO habito_recomendado (clave, subcategoria_id, nombre, unidad, meta, frecuencia_tipo, dias_semana,
                                        veces_semana, momento, porque, fuentes, orden, activo)
        VALUES (p_clave, p_subcategoria, btrim(p_nombre), p_unidad, p_meta, p_frecuencia_tipo, p_dias_semana,
                p_veces_semana, btrim(p_momento), btrim(p_porque), p_fuentes, coalesce(p_orden, 99),
                coalesce(p_activo, true))
        ON CONFLICT (clave) DO UPDATE
           SET subcategoria_id = EXCLUDED.subcategoria_id, nombre = EXCLUDED.nombre, unidad = EXCLUDED.unidad,
               meta = EXCLUDED.meta, frecuencia_tipo = EXCLUDED.frecuencia_tipo,
               dias_semana = EXCLUDED.dias_semana, veces_semana = EXCLUDED.veces_semana,
               momento = EXCLUDED.momento, porque = EXCLUDED.porque, fuentes = EXCLUDED.fuentes,
               orden = EXCLUDED.orden, activo = EXCLUDED.activo, actualizado_en = now()
        RETURNING id INTO p_id;
    EXCEPTION WHEN check_violation OR not_null_violation THEN
        RAISE EXCEPTION 'Recomendación inválida (clave, nombre, frecuencia, momento o por qué)' USING ERRCODE = 'KZ011';
    END;
    PERFORM fn_auditar(p_admin, v_region_admin, 'admin.recomendacion_guardar', 'recomendacion/' || p_id, 'exito', p_ip);
END;
$$;

-- =====================================================================
-- 6. Permisos
-- =====================================================================
REVOKE ALL ON FUNCTION fn_fuentes_validas(text), fn_dias_protegidos(region_t, uuid, date, date),
                       tg_habito_recomendacion() FROM PUBLIC;
REVOKE ALL ON PROCEDURE sp_admin_guardar_recomendacion FROM PUBLIC;

-- kaizen_api: lee el catálogo, crea hábitos desde una recomendación y consulta los días protegidos
GRANT SELECT ON fuente_cientifica, habito_recomendado, v_habito_recomendado TO kaizen_api;
GRANT INSERT (recomendacion_id) ON habito TO kaizen_api;
GRANT EXECUTE ON FUNCTION fn_dias_protegidos(region_t, uuid, date, date), fn_fuentes_validas(text) TO kaizen_api;
GRANT EXECUTE ON PROCEDURE sp_admin_guardar_recomendacion TO kaizen_api;

-- kaizen_etl (solo lectura): qué hábitos salieron de una recomendación (habito.recomendacion_id ya
-- está cubierto por su SELECT sobre habito)
GRANT SELECT ON fuente_cientifica, habito_recomendado, v_habito_recomendado TO kaizen_etl;
GRANT EXECUTE ON FUNCTION fn_dias_protegidos(region_t, uuid, date, date) TO kaizen_etl;

-- kaizen_admin (personas)
GRANT SELECT ON fuente_cientifica, habito_recomendado, v_habito_recomendado TO kaizen_admin;
GRANT EXECUTE ON FUNCTION fn_dias_protegidos(region_t, uuid, date, date), fn_fuentes_validas(text) TO kaizen_admin;

COMMIT;
