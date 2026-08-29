# Rangos de Referencia para la Interpretación de Análisis de Suelo en Café

**Parámetros de implementación para Agrifos y variación entre variedades**
Proyecto Agrifos — 23 de agosto de 2026

---

## Resumen

Este documento establece rangos de referencia para interpretar un análisis de suelo aplicado al cultivo de café (*Coffea arabica*), incluyendo pH, conductividad eléctrica, textura, materia orgánica, calcio, magnesio, sodio, potasio, zinc, hierro, manganeso, cobre, níquel, nitrato-nitrógeno, fosfato, sulfato, boro, porcentaje de sodio intercambiable, capacidad de intercambio catiónico y saturación de bases. La referencia principal corresponde a Cenicafé, complementada con instituciones cafetaleras de Centroamérica.

Se distingue entre niveles críticos validados para café y rangos operativos orientativos, debido a que la interpretación depende del método de extracción, la unidad, la textura, el material parental y la etapa fenológica. Finalmente, se analiza si Caturra, Borbón y Catuaí requieren rangos óptimos distintos: la evidencia disponible no justifica asignar un pH o un nivel crítico de nutrientes diferente para cada variedad; las diferencias varietales influyen más en demanda nutricional, productividad, adaptación climática y respuesta al manejo.

**Palabras clave:** café, análisis de suelo, fertilidad, Caturra, Borbón, Catuaí, Agrifos.

---

## Introducción

La interpretación de un análisis de suelo no consiste únicamente en comparar cada resultado con un valor universal. Un resultado solo adquiere significado cuando se conoce el método de extracción, la profundidad de muestreo, la unidad empleada y la relación entre el nivel medido y la respuesta del cultivo. Cenicafé advierte que las categorías de bajo, medio y alto deben sustentarse en métodos específicos previamente relacionados con la respuesta de la planta (Sadeghian, 2018, 2020).

Esta condición es especialmente importante en suelos volcánicos de Centroamérica, donde la retención de fósforo, la acidez y la materia orgánica pueden modificar la disponibilidad real de los nutrientes.

> [!IMPORTANT]
> Agrifos debe conservar junto a cada resultado el método de laboratorio utilizado, porque las escalas de interpretación no son intercambiables entre pasta saturada, acetato de amonio, DTPA, reducción de cadmio, Olsen y agua caliente. Sin esos metadatos, la clasificación automática puede producir falsos diagnósticos.

---

## Alcance y criterios de interpretación

Los rangos de Cenicafé se formularon para café en etapa de producción y con metodologías de laboratorio definidas. Cuando el laboratorio utiliza un método distinto, el rango se presenta como referencia orientativa y no como nivel crítico universal.

- **Anacafé** mantiene el mismo principio: la interpretación requiere conocer la metodología de extracción y la calidad del muestreo (Asociación Nacional del Café [Anacafé], s. f.).
- **IHCAFE** indica que la fertilización debe basarse en la interpretación del análisis de suelo y no en la elección aislada de un fertilizante (Instituto Hondureño del Café [IHCAFE], s. f.).
- **ICAFE** (Costa Rica) utiliza métodos diferenciados para pH, materia orgánica, P, K, Ca, Mg y micronutrientes, lo que confirma la necesidad de conservar el método junto al resultado (Instituto del Café de Costa Rica [ICAFE], s. f.).

### Metadatos requeridos por Agrifos por cada resultado

| Campo | Descripción |
|---|---|
| `metodo` | Método de extracción (Bray II, Mehlich 3, DTPA, agua caliente, etc.) |
| `unidad` | Unidad del reporte (mg/kg, cmol(+)/kg, %, dS/m) |
| `profundidad_cm` | Profundidad de muestreo |
| `fecha_muestreo` | Fecha en que se tomó la muestra |
| `etapa_cultivo` | Etapa fenológica del cultivo al momento del muestreo |
| `nivel_confianza` | Alta / Media / Baja según respaldo de fuente |

---

## Parámetros de suelo y rangos de referencia

En los cationes intercambiables se muestran equivalencias aproximadas a mg/kg para facilitar la comparación con informes comerciales. Las equivalencias **no** sustituyen la unidad original del laboratorio.

### Tabla 1. Rangos de referencia para café (Cenicafé / Instituciones CA)

| Parámetro | Unidad | Bajo | Adecuado / Rango óptimo | Alto | Método de referencia | Confianza | Fuente |
|---|---|---|---|---|---|---|---|
| **pH** | SU | <5.0 | **5.0–5.5** | >6.0 (puede inducir def.) | Agua (1:1) | Alta | Cenicafé |
| **Conductividad eléctrica** | dS/m | — | <1.0 | >1.1 (riesgo) | Pasta saturada | Media | Cenicafé |
| **Materia orgánica** | % | <8 | **8–16** | >16 (no necesariamente mejor) | Walkley-Black | Alta | Cenicafé |
| **Nitrógeno total** | mg/kg | <*3,400* | **3,400–5,800** | >5,800 | Kjeldahl (N% × 10,000) | Alta | Cenicafé |
| **Fósforo disponible** | mg/kg | <8 | **8–30** | >30 | Bray II / Mehlich 3 | Alta | Cenicafé |
| **Calcio intercambiable** | mg/kg | <301 | **301–601** | >601 (generalmente favorable) | Acetato de amonio | Alta | Cenicafé |
| **Magnesio intercambiable** | mg/kg | <73 | **73–109** | >109 (revisar Ca:Mg) | Acetato de amonio | Alta | Cenicafé |
| **Potasio intercambiable** | mg/kg | <78 | **78–156** | >156 | Acetato de amonio | Alta | Cenicafé |
| **Sodio intercambiable** | mg/kg | — | <100 (objetivo operativo) | >100 (vigilar sodicidad) | Acetato de amonio | Media | Cenicafé |
| **Azufre disponible** | mg/kg | <5 | **5–15** | >15 | Acetato de amonio cálcico | Media | Cenicafé / ICAFE |
| **Zinc (Zn)** | mg/kg | <1.0 | **1.5–3.0** | >5.0 | DTPA | Media | Cenicafé |
| **Hierro (Fe)** | mg/kg | <5 | **>10** | >50 (puede antagonizar) | DTPA | Media | Cenicafé |
| **Manganeso (Mn)** | mg/kg | <1 | **2–5** | >10 (toxicidad posible en pH bajo) | DTPA | Media | Cenicafé |
| **Cobre (Cu)** | mg/kg | <0.2 | **0.5–1.5** | >3.0 | DTPA | Media | Cenicafé |
| **Boro (B)** | mg/kg | <0.3 | **0.5–1.0** | >2.0 | Agua caliente | Media | Cenicafé / ICAFE |
| **CIC** | cmol(+)/kg | <10 | **15–30** | — | Acetato de amonio | Media | Cenicafé |
| **Saturación de bases** | % | <50 | **>60** | — | Calculada de CIC | Media | Cenicafé |
| **PSI (% Na intercambiable)** | % | — | <10 | >15 (riesgo estructural) | Calculado | Media | Literatura |

### Tabla 2. Relaciones catiónicas de referencia

| Relación | Rango adecuado | Consecuencia de desequilibrio |
|---|---|---|
| Ca:Mg | 5:1 – 8:1 | Ratio bajo → exceso Mg bloquea Ca; ratio alto → def. Mg |
| Ca:K | 25:1 – 40:1 | Exceso K puede inducir def. Ca o Mg |
| Mg:K | 3:1 – 5:1 | Desequilibrio frecuente en suelos con exceso de K |
| (Ca+Mg):K | 30:1 – 50:1 | Referencia global de balance catiónico |

---

## Interpretación por parámetro

### pH

El rango adecuado para café es **5.0–5.5**. Por debajo de 5.0 puede haber toxicidad de aluminio (Al³⁺) y manganeso; por encima de 6.0 puede haber precipitación de fósforo y zinc. La corrección de pH se realiza con cal dolomítica (aporta Ca y Mg simultáneamente).

**Regla de encalado en Agrifos:**

| pH medido | Acción |
|---|---|
| < 4.5 | Encalado urgente; bloquear fertilización N-P-K hasta corregir |
| 4.5–5.0 | Encalado recomendado; aplicar fertilizantes con precaución |
| 5.0–5.5 | Rango óptimo; continuar con plan de fertilización |
| 5.5–6.0 | Aceptable; monitorear micronutrientes |
| > 6.0 | Revisar disponibilidad de P, Zn, Fe, Mn |

### Materia orgánica (MO)

La MO es clave en suelos cafetaleros: retiene humedad, aporta CIC y libera N por mineralización. Un valor < 8% indica degradación; > 16% no mejora automáticamente la producción. **Tasa de mineralización estimada:** 2–3% anual del N total en MO, dependiente de temperatura y humedad.

### Fósforo disponible

El método de extracción es crítico:
- **Bray II** → rango 8–30 mg/kg para café
- **Mehlich 3** → valores similares a Bray II en suelos no volcánicos
- **Olsen** → rangos diferentes; no usar con el mismo umbral que Bray II

En suelos volcánicos (Andisoles) de Nicaragua, la retención de P puede ser muy alta. En estos casos, aumentar la dosis de P o usar fuentes de liberación lenta (roca fosfórica).

### Micronutrientes

Los micronutrientes se extraen con DTPA (Zn, Fe, Mn, Cu) y agua caliente (B). Los métodos no son intercambiables. Agrifos debe registrar el método junto al valor y mostrar el umbral correspondiente.

---

## Diferencias entre variedades (Caturra, Borbón, Catuaí)

La evidencia científica disponible (Cenicafé, World Coffee Research) **no justifica** asignar rangos críticos de pH o nutrientes diferentes para Caturra, Borbón y Catuaí. Los tres materiales son *Coffea arabica* y responden a los mismos procesos edáficos.

**Las diferencias varietales sí se expresan en:**

| Variable | Caturra | Borbón | Catuaí |
|---|---|---|---|
| Demanda nutricional relativa | Alta | Media | Alta |
| Sensibilidad a déficit de K | Alta | Media | Alta |
| Densidad de siembra (plantas/ha) | 5,000–6,000 | 3,500–4,500 | 5,000–6,000 |
| Respuesta al encalado | Similar | Similar | Similar |
| Adaptación climática | Media altitud | Alta altitud | Media-alta altitud |

**Conclusión para Agrifos:** usar los mismos rangos de referencia de suelo para las tres variedades; ajustar solo la **demanda nutricional** (factor varietal en el motor de fertilización) según rendimiento objetivo y densidad.

---

## Guía de implementación en Agrifos

### Flujo de diagnóstico

```
Input: resultado_laboratorio + metodo + unidad + profundidad + fecha + etapa

1. Normalizar unidades → mg/kg o cmol(+)/kg
2. Para cada parámetro:
   a. Buscar rango correspondiente al método
   b. Clasificar: Bajo / Adecuado / Alto
   c. Si método no coincide → mostrar como "referencia orientativa"
3. Calcular relaciones Ca:Mg, Ca:K, Mg:K
4. Si pH < 5.0 → generar alerta de encalado
5. Si CE > 1.1 → generar alerta de salinidad
6. Pasar S_a al motor de fertilización como kg/ha
```

### Etiquetas de confianza en la UI

| Etiqueta | Condición | Color sugerido |
|---|---|---|
| ✅ Nivel crítico validado | Método coincide con fuente; Cenicafé o equivalente | Verde |
| ⚠️ Referencia orientativa | Método distinto al de la fuente | Amarillo |
| ❌ Dato insuficiente | Sin método registrado | Rojo |
| 🔬 Referencia transferida | Calibrado en Colombia; no validado en Nicaragua | Gris |

---

## Referencias

- Asociación Nacional del Café [Anacafé]. (s. f.). *Interpretación del análisis de suelos para café*. Anacafé.
- Instituto del Café de Costa Rica [ICAFE]. (s. f.). *Guía de interpretación de análisis de suelo para café*. ICAFE.
- Instituto Hondureño del Café [IHCAFE]. (s. f.). *Manual de fertilización del café en Honduras*. IHCAFE.
- Sadeghian, S. (2009). *Fertilidad del suelo y nutrición del café en Colombia: Guía práctica*. Cenicafé.
- Sadeghian, S. (2018). *Interpretación del análisis de suelos para el cultivo de café*. Cenicafé, Avances Técnicos, (494).
- Sadeghian, S. (2020). *Actualización de niveles críticos de nutrientes para café en Colombia*. Cenicafé.
- World Coffee Research. (s. f.). *Variety catalog — Caturra, Bourbon, Catuaí*. https://varieties.worldcoffeeresearch.org
