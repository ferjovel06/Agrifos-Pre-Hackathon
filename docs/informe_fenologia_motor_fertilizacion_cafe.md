# Etapa Fenológica y Motor Matemático de Fertilización para Café

**Documento técnico de investigación y especificación para implementación**

Variedades consideradas: Caturra, Borbón y Catuaí
Contexto de uso: fincas cafetaleras de Nicaragua y Centroamérica
Versión 1.0 — 25 de agosto de 2026
Elaborado para orientar el desarrollo del módulo de análisis agronómico de Agrifos.

---

## Resumen

Este documento presenta una propuesta técnica para que Agrifos determine la etapa fenológica del cafeto y genere recomendaciones de fertilización a partir de datos de edad del cultivo, calendario, altitud, observaciones de floración, lecturas de un sensor siete en uno y análisis de laboratorio. La propuesta se construye alrededor de tres variedades de *Coffea arabica* L. contempladas en el proyecto: Caturra, Borbón y Catuaí. La evidencia principal procede de Cenicafé, World Coffee Research y una guía técnica validada en fincas del centro-norte de Nicaragua. Se adopta un enfoque híbrido: la edad en meses clasifica el ciclo de vida; la fecha de floración determina la edad del fruto; la altitud ajusta la duración esperada; y el color o estado observado del fruto confirma la madurez antes de recomendar cosecha.

Para fertilización, se evita restar directamente todo el resultado de laboratorio a la demanda del cultivo, porque P, K, N y S dependen del método analítico, la mineralización, la capacidad de intercambio y la respuesta local. El motor propuesto convierte unidades, valida calidad de datos, interpreta niveles críticos calibrados, estima demanda por rendimiento y estado fenológico, y resuelve una combinación de fertilizantes mediante programación lineal.

**Palabras clave:** café, *Coffea arabica*, fenología, fertilización, análisis de suelo, Caturra, Borbón, Catuaí, Nicaragua.

> [!WARNING]
> Los rangos y ecuaciones de este documento son una especificación inicial para software y apoyo a la decisión. No sustituyen un análisis de laboratorio, la validación de un agrónomo ni un ensayo local de respuesta. Las publicaciones de Cenicafé son una referencia regional sólida, pero sus niveles críticos fueron calibrados principalmente en Colombia; por ello, Agrifos debe etiquetar como *"referencia transferida"* cualquier umbral que todavía no haya sido calibrado en Nicaragua (Sadeghian, 2009, 2020).

---

## Contenido

1. [Alcance y fuentes de evidencia](#1-alcance-y-fuentes-de-evidencia)
2. [Variedades y diferencias agronómicas](#2-variedades-y-diferencias-agronómicas)
3. [Modelo de etapa fenológica](#3-modelo-de-etapa-fenológica)
4. [Calendario anual para Nicaragua](#4-calendario-anual-para-nicaragua)
5. [Datos y reglas de implementación fenológica](#5-datos-y-reglas-de-implementación-fenológica)
6. [Necesidades nutricionales del cafeto](#6-necesidades-nutricionales-del-cafeto)
7. [Normalización de unidades y calidad de datos](#7-normalización-de-unidades-y-calidad-de-datos)
8. [Interpretación del análisis de laboratorio](#8-interpretación-del-análisis-de-laboratorio)
9. [Ruta del sensor siete en uno](#9-ruta-del-sensor-siete-en-uno)
10. [Motor matemático de fertilización](#10-motor-matemático-de-fertilización)
11. [Catálogo de fertilizantes](#11-catálogo-de-fertilizantes)
12. [Optimización de dosis y fraccionamiento](#12-optimización-de-dosis-y-fraccionamiento)
13. [Salidas para la aplicación](#13-salidas-para-la-aplicación)
14. [Ejemplos de cálculo](#14-ejemplos-de-cálculo)
15. [Validación y hoja de ruta](#15-validación-y-hoja-de-ruta)
16. [Limitaciones y conclusiones](#16-limitaciones-y-conclusiones)
17. [Referencias](#17-referencias)

---

## Resumen ejecutivo

La aplicación debe responder dos preguntas diferentes: *¿en qué etapa de vida está la planta?* y *¿en qué etapa está el fruto de esta floración?* La primera depende de los meses desde el trasplante; la segunda depende de los días desde floración. Una parcela puede tener varias floraciones y, por tanto, simultáneamente frutos en cuajado, llenado y maduración. El modelo no debe guardar una sola etapa rígida para toda la parcela.

- **Ciclo de vida:** vivero, establecimiento, levante, primera producción y producción estable.
- **Fenología reproductiva:** prefloración, floración, cuajado, expansión, llenado, maduración y cosecha.
- **Prioridad de evidencia:** observación de floración y fruto > registro de lluvia/humedad > calendario mensual.
- **Ruta de laboratorio:** interpretación completa de pH, materia orgánica, CIC, textura, N, P, K, Ca, Mg y S; añadir Al intercambiable o acidez de reserva para calcular encalado.
- **Ruta de sensor:** diagnóstico preliminar de pH, humedad, temperatura, CE, N, P y K; sin recomendar cal, Ca, Mg, S u orgánicos sin datos adicionales.
- **Fertilizantes:** urea, DAP y KCl permanecen como opciones, pero se agregan MAP, TSP, sulfato de amonio, sulfato de potasio, nitrato de potasio, nitrato de calcio, kieserita, yeso, cal dolomítica y fórmulas NPK.

---

## 1. Alcance y fuentes de evidencia

El alcance corresponde a un módulo de apoyo a decisiones para parcelas de café arábica. El módulo debe trabajar con la información disponible en el repositorio Agrifos: variedad, edad, parcela, lecturas de sensor, parámetros de laboratorio y registros fenológicos. El objetivo no es crear una tabla universal que funcione igual en todos los suelos, sino establecer una línea base transparente que pueda actualizarse con resultados de parcelas nicaragüenses.

### 1.1 Jerarquía de fuentes

| Nivel | Fuente | Uso en Agrifos |
|---|---|---|
| 1 | Ensayo local y recomendación de laboratorio | Umbrales y dosis definitivas por región, método y cultivo |
| 2 | Guía validada en centro-norte de Nicaragua | Calendario operativo, prácticas de finca y contexto regional (Moraga, 2024) |
| 3 | Cenicafé | Fenología, extracción de nutrientes, calibración de análisis y fertilización por etapas |
| 4 | World Coffee Research | Rasgos comparativos de Caturra, Borbón y Catuaí; no reemplaza calibración nutricional local |
| 5 | Literatura general | Conversión de unidades, formulación y restricciones químicas |

> [!NOTE]
> Las recomendaciones generales de fertilización de Cenicafé se desarrollaron para condiciones colombianas y deben mostrarse en la aplicación con la etiqueta *"referencia regional"*.

### 1.2 Principio de trazabilidad

Cada resultado de Agrifos debe guardar la fuente de cada umbral: método de laboratorio, publicación, fecha de calibración, región, variedad, nivel de confianza y versión del motor. Así, la app puede explicar por qué clasificó un dato como bajo, adecuado o alto y permite sustituir los valores de referencia por datos de ensayos locales sin reescribir el software.

---

## 2. Variedades y diferencias agronómicas

Las tres variedades pertenecen al grupo de café arábica usado en Centroamérica.

### Tabla 1. Perfil de las tres variedades contempladas en Agrifos

| Variedad | Arquitectura | Primer año de producción | Nutrición relativa | Maduración | Densidad de referencia |
|---|---|---|---|---|---|
| Caturra | Compacta | Año 3 | Alta | Promedio | 5,000–6,000 plantas/ha |
| Borbón | Alta | Año 4 | Media | Temprana | 3,500–4,500 plantas/ha |
| Catuaí | Compacta | Año 3 | Alta | Promedio | 5,000–6,000 plantas/ha |

*Nota: Los años de primer producción son estimaciones regionales para Nicaragua. Pueden variar según altitud, manejo y densidad de siembra.*

### 2.1 Cómo modelar la variación entre variedades

La diferencia varietal debe entrar al motor mediante variables observables: densidad, carga de fruto, rendimiento objetivo, edad, vigor y clase de maduración. No se recomienda aplicar factores arbitrarios sin datos de campo. El motor inicia con factor varietal 1.00 y utiliza la información de WCR para advertencias de manejo; después puede aprender un factor calibrado por variedad y zona.

```
Demanda ajustada = demanda base × factor de densidad × factor de carga
                   × factor de edad × factor calibrado de variedad
```

En esta versión, el factor calibrado de variedad se mantiene en 1.00 por defecto y se registra como parámetro pendiente de validación. Borbón puede adelantar la ventana de maduración como clase "temprana", pero no se fija una cantidad de días universal sin un conjunto local de fechas de floración y cosecha.

---

## 3. Modelo de etapa fenológica

El desarrollo del fruto desde floración hasta maduración dura en promedio 32 semanas. En zonas por debajo de 1,200 m puede durar 28–30 semanas; por encima de 1,700 m, 34–36 semanas. Cenicafé divide el proceso en una primera etapa de crecimiento lento hasta la semana 8, una segunda de crecimiento rápido entre las semanas 9 y 26 y una tercera de cambio de color y madurez fisiológica entre las semanas 27 y 32 (Salazar-Gutiérrez et al., 1993).

### Tabla 2. Estados fenológicos del fruto para el motor

| Estado | Días desde floración | Señal biológica | Decisión en la app |
|---|---|---|---|
| Prefloración | Antes del día 0 | Yemas diferenciadas; respuesta a periodo seco y primeras lluvias | Avisar preparación de floración y revisar nutrición equilibrada |
| Floración | 0–7 | Flores abiertas; fecha de evento registrada | Crear cohorte de floración y comenzar contador DAF |
| Cuajado / "cabeza de fósforo" | 8–56 | Fruto verde pequeño; crecimiento lento | Evitar interpretar como falta de cosecha; priorizar humedad y sanidad |
| Expansión rápida | 57–120 | Aumento de tamaño y peso; alta demanda de agua y N/K | Programar fraccionamiento; vigilar estrés hídrico |
| Llenado y endurecimiento | 121–182 | Se forma y endurece el endospermo; cambia la relación agua/materia seca | Ajustar K y balance; evitar exceso de N tardío |
| Maduración fisiológica | 183–224 típico | Cambio de verde a rojo o amarillo según material | Iniciar cosecha selectiva si la observación confirma color |
| Ventana tardía por altitud | 225–252 | Maduración retrasada en zonas altas o por clima | Mantener monitoreo; no declarar listo solo por calendario |

*DAF = días después de floración. La ventana de maduración se ajusta por altitud y se confirma con observación. "Listo para cosecha" requiere color de cereza y criterio de calidad, no solamente el número de días.*

### 3.1 Edad de la planta en meses

| Edad aproximada | Etapa de vida | Indicadores | Regla inicial para la app |
|---|---|---|---|
| 0–3 meses | Vivero inicial | Plántula, hojas cotiledonares y primeras hojas verdaderas | No emitir dosis productiva; registrar riego, sustrato y sanidad |
| 4–8 meses | Vivero avanzado | Sistema radical y tallo en formación | Nutrientes fraccionados; evitar salinidad y sobredosis |
| 9–12 meses | Establecimiento | Trasplante, adaptación y emisión de hojas nuevas | Estado "establecimiento"; priorizar humedad y P de arranque |
| 13–24 meses | Levante | Crecimiento vegetativo; formación de ramas y bandolas | Plan de N; P más importante al inicio; K y Mg aumentan con edad |
| 25–36 meses | Transición a producción | Puede aparecer primera cosecha en Caturra/Catuaí | Separar demanda vegetativa y demanda de fruto |
| 37–48 meses | Producción inicial | Producción más regular; Borbón puede iniciar alrededor del año 4 | Usar rendimiento objetivo y carga observada |
| >48 meses | Producción estable | Ciclos anuales, podas y renovación de ramas | Usar balance anual, análisis de suelo y extracción por cosecha |

*Los cortes mensuales son reglas de software, no límites fisiológicos rígidos. Deben parametrizarse por vivero, fecha de trasplante, altitud y manejo.*

---

## 4. Calendario anual para Nicaragua

La guía técnica validada en fincas de la zona centro-norte de Nicaragua indica que la activación y diferenciación de yemas productivas se relaciona con el periodo seco, las lluvias y el manejo de sombra; también señala que las ramas nuevas se forman principalmente entre febrero y septiembre y que el ciclo productivo comprende prefloración, floración, postfloración, crecimiento/llenado y maduración (Moraga, 2024). Por la variabilidad de Nicaragua, el calendario debe ser un "prior" regional y no la única fuente de decisión.

### Tabla 3. Calendario inicial configurable por mes

| Mes | Etapa predominante esperada | Actividad de Agrifos | Confianza |
|---|---|---|---|
| Enero | Cosecha tardía, postcosecha y vegetativo | Registrar cosecha, poda, sombra, suelo y recuperación | Media |
| Febrero | Postcosecha y crecimiento vegetativo | Actualizar edad, vigor, sombra y fertilidad; preparar muestreo | Media |
| Marzo | Prefloración / primeras floraciones | Registrar fecha exacta de cada floración; no usar un único evento | Baja–media |
| Abril | Floración y cuajado | Crear cohortes; controlar humedad y eventos de lluvia | Media |
| Mayo | Cuajado y expansión temprana | Revisar supervivencia de frutos y fraccionar nutrientes | Media |
| Junio | Expansión rápida | Monitorear agua, N, K y vigor de ramas | Media |
| Julio | Expansión y transición a llenado | Registrar estado de fruto por muestreo | Media |
| Agosto | Llenado y endurecimiento inicial | Evitar exceso de N; revisar K, Mg y humedad | Media |
| Septiembre | Llenado y nuevas ramas | Actualizar cohortes; ajustar por altitud y lluvia | Media |
| Octubre | Maduración en zonas tempranas | Cosecha selectiva donde el color lo confirme | Media |
| Noviembre | Maduración y cosecha principal | Activar alerta de cosecha; controlar frutos sobremaduros | Media–alta |
| Diciembre | Cosecha, postcosecha y prefloración siguiente | Cerrar balance de rendimiento y nutrientes extraídos | Media |

*Este calendario debe tener configuración por departamento, municipio, altitud y patrón de lluvias. El sistema debe permitir registrar más de una floración en el mismo año.*

### 4.1 Ajuste por altitud

| Altitud | Duración de referencia floración–madurez | Regla de cálculo |
|---|---|---|
| <1,200 m | 196–210 días | Ventana rápida; revisar cosecha desde DAF 183 |
| 1,200–1,700 m | ≈224 días | Ventana base; revisar desde DAF 196–224 |
| >1,700 m | 238–252 días | Ventana lenta; no declarar madurez antes de observación |

---

## 5. Datos y reglas de implementación fenológica

El módulo fenológico debe operar con **cohortes**. Una cohorte es un conjunto de flores o frutos originados por un evento de floración observado en una fecha determinada. Para cada cohorte se almacenan: fecha, porcentaje estimado de plantas o bandolas afectadas, variedad, altitud, observación de color y nivel de confianza.

### 5.1 Algoritmo de clasificación

```
Si cohorte existe AND DAF calculado:
    etapa_fruto = tabla_fenologica(DAF, altitud)
    ajuste_altitud = factor(altitud)

Si observacion_color disponible:
    confirmar o corregir etapa_fruto

Si edad_planta_meses disponible:
    etapa_vida = tabla_ciclo_vida(meses)

Si etapa_vida = vivero OR establecimiento:
    bloquear recomendacion_productiva
    emitir solo nutricion_basica
```

### 5.2 Prioridad de evidencia (en orden descendente)

1. **Observación directa de floración/fruto** — registrada con fecha y % de bandolas
2. **Registro de lluvia o humedad de suelo** — útil para confirmar la activación fenológica
3. **Calendario regional** — como referencia inicial o cuando no hay observaciones

---

## 6. Necesidades nutricionales del cafeto

### 6.1 Extracción por macronutriente

| Nutriente | Extracción anual base (producción alta) | Factor varietal Caturra | Factor varietal Borbón | Factor varietal Catuaí |
|---|---|---|---|---|
| N | 120–150 kg/ha | 1.05 | 0.95 | 1.10 |
| P₂O₅ | 20–30 kg/ha | 1.05 | 0.95 | 1.10 |
| K₂O | 130–160 kg/ha | 1.05 | 0.95 | 1.10 |

> [!NOTE]
> Los factores varietales son valores de referencia inicial (Cenicafé, 2013). Agrifos debe registrarlos como "pendientes de calibración local" y actualizarlos con datos de fincas nicaragüenses.

### 6.2 Distribución fenológica de la demanda (fracción $f_e$ por etapa)

| Etapa del fruto | N | P | K |
|---|---|---|---|
| Cuajado | 0.15 | 0.25 | 0.10 |
| Expansión rápida | 0.35 | 0.30 | 0.35 |
| Llenado y endurecimiento | 0.30 | 0.25 | 0.35 |
| Maduración | 0.20 | 0.20 | 0.20 |

---

## 7. Normalización de unidades y calidad de datos

### 7.1 Conversiones principales

| Unidad de entrada | Conversión | Resultado |
|---|---|---|
| ppm (mg/kg) de N, P | × Masa de suelo (kg/ha) ÷ 10⁶ × F_ox | kg/ha |
| cmol(+)/kg de K | × 391 × Masa de suelo ÷ 10⁶ × 1.205 | kg/ha de K₂O |
| % N → mg/kg | × 10,000 | mg/kg |
| Masa de suelo (Ms) | A × Pr × Da × 1,000 | kg/ha |

Donde A = 10,000 m², Pr = profundidad de raíces (m), Da = densidad aparente (ton/m³).

### 7.2 Reglas de validación de datos

- Si pH < 4.0 o pH > 9.0 → rechazar lectura
- Si CE > 4.0 dS/m → marcar alerta de salinidad
- Si N_sensor > 500 mg/kg → verificar calibración del sensor
- Si MO > 20% → posible suelo orgánico; ajustar Da
- Conservar siempre el método de extracción junto al resultado

---

## 8. Interpretación del análisis de laboratorio

Ver documento complementario [`parametros_laboratorio_cafe.md`](./parametros_laboratorio_cafe.md) para la tabla completa de rangos de referencia Cenicafé/Anacafé/IHCAFE/ICAFE por parámetro.

### 8.1 Flujo de interpretación

```
Para cada parámetro:
  1. Verificar método de extracción
  2. Convertir a unidad estándar del motor
  3. Comparar con rango de referencia
  4. Clasificar: Bajo / Adecuado / Alto
  5. Etiquetar confianza: Alta / Media / Baja (según fuente)
  6. Si método desconocido → etiquetar como "referencia orientativa"
```

---

## 9. Ruta del sensor siete en uno

El sensor proporciona lecturas de: Humedad (%), Temperatura (°C), pH, CE (dS/m), N (mg/kg), P (mg/kg), K (mg/kg).

### 9.1 Calibración y ajuste

$$C_{ajustada(i)} = g(Lectura_{sensor(i)},\ \theta,\ T,\ pH)$$

Corrección térmica de CE:

$$CE_{25} = \frac{CE_T}{1 + 0.02(T - 25)}$$

### 9.2 Limitaciones de la ruta sensor

- **No se puede recomendar:** cal, Ca, Mg, S, micronutrientes, encalado
- **Se puede recomendar:** dosis preliminar de N, P, K con advertencia de calibración
- **Siempre mostrar:** etiqueta "diagnóstico preliminar – confirmar con laboratorio"

---

## 10. Motor matemático de fertilización

Ver [`agrifos_engine_documentation.md`](./agrifos_engine_documentation.md) para las ecuaciones completas.

### 10.1 Flujo del motor

```
Entrada: lectura_sensor OR analisis_laboratorio
         + variedad + etapa + rendimiento_objetivo + densidad

Paso A: D_c = R_obj × I_e(i) × f_v(i) × f_e(i)
Paso B: S_a = f(concentracion, masa_suelo, factor_oxido)
Paso C: D_f = (D_c - S_a) / E_f
Salida: Cascada de fertilizantes → dosis en kg/ha y oz/planta
```

---

## 11. Catálogo de fertilizantes

### 11.1 Fertilizantes químicos (catálogo extendido)

| Fertilizante | Símbolo | N% | P₂O₅% | K₂O% | S% | Ca% | Mg% | Notas |
|---|---|---|---|---|---|---|---|---|
| Urea | CO(NH₂)₂ | 46 | — | — | — | — | — | Alta solubilidad; riesgo de volatilización |
| DAP | (NH₄)₂HPO₄ | 18 | 46 | — | — | — | — | Fuente binaria principal |
| MAP | NH₄H₂PO₄ | 11 | 52 | — | — | — | — | Mayor concentración de P; pH ligeramente ácido |
| TSP | Ca(H₂PO₄)₂ | — | 46 | — | — | 14 | — | Sin N; útil cuando N ya es suficiente |
| KCl | KCl | — | — | 60 | — | — | — | Fuente estándar de K |
| Sulfato de potasio | K₂SO₄ | — | — | 50 | 18 | — | — | Preferible en suelos clorosensibles o con déficit de S |
| Nitrato de potasio | KNO₃ | 13 | — | 44 | — | — | — | Aporta N y K simultáneamente |
| Sulfato de amonio | (NH₄)₂SO₄ | 21 | — | — | 24 | — | — | Acidificante; útil en suelos con pH alto |
| Nitrato de calcio | Ca(NO₃)₂ | 15.5 | — | — | — | 19 | — | Aporta N y Ca; no acidifica |
| Kieserita | MgSO₄·H₂O | — | — | — | 22 | — | 18 | Fuente de Mg y S |
| Yeso agrícola | CaSO₄·2H₂O | — | — | — | 17 | 23 | — | No afecta pH; corrige Ca y S |
| Cal dolomítica | CaMg(CO₃)₂ | — | — | — | — | 21 | 12 | Encalado; eleva pH y aporta Ca+Mg |
| Fórmulas NPK | variable | variable | variable | variable | — | — | — | Seleccionar según déficit dominante |

### 11.2 Fertilizantes orgánicos (tasas de mineralización)

| Insumo | N% | P% | K% | Tasa de mineralización (Mt) año 1 |
|---|---|---|---|---|
| Bocashi | 1.5–2.5 | 1.0–2.0 | 1.0–2.0 | 0.60 |
| Humus de lombriz | 1.0–2.0 | 1.0–1.5 | 1.0–1.5 | 0.70 |
| Roca fosfórica | — | 20–30 (P₂O₅) | — | 0.10–0.20 (pH ácido) |
| Compost maduro | 1.0–2.0 | 0.5–1.0 | 0.8–1.5 | 0.40–0.50 |

---

## 12. Optimización de dosis y fraccionamiento

### 12.1 Orden de cálculo (cascada química)

1. **DAP** → cubre P primero, aporta N secundario
2. **MAP** → alternativa si se requiere menos N con el P
3. **Urea** → complementa el déficit de N no cubierto por DAP/MAP
4. **KCl** o **K₂SO₄** → cubre déficit de K (elegir K₂SO₄ si hay déficit de S o suelo clorosensible)
5. **Kieserita** → si hay déficit de Mg
6. **Cal dolomítica** → si pH < 5.0 (bloquea aplicación de fertilizantes solubles hasta que suba)

### 12.2 Fraccionamiento recomendado

| Etapa | % de la dosis anual N | % P | % K |
|---|---|---|---|
| Inicio de cuajado | 25% | 40% | 20% |
| Expansión rápida | 35% | 30% | 35% |
| Llenado | 25% | 20% | 30% |
| Postcosecha / recuperación | 15% | 10% | 15% |

---

## 13. Salidas para la aplicación

Cada recomendación del motor debe incluir:

| Campo | Descripción |
|---|---|
| `fertilizante` | Nombre del producto |
| `dosis_kg_ha` | Dosis en kg/ha |
| `dosis_oz_planta` | Dosis en oz/planta (conversión por densidad) |
| `momento_aplicacion` | Etapa fenológica recomendada |
| `fuente_umbral` | Publicación o método base del cálculo |
| `nivel_confianza` | Alta / Media / Baja |
| `advertencia` | Texto de advertencia si aplica (ej. riesgo climático, calibración pendiente) |

---

## 14. Ejemplos de cálculo

### Ejemplo A — Sensor 7 en 1, Caturra en expansión rápida

- Lectura N = 38 mg/kg, P = 12 mg/kg, K = 55 mg/kg
- Rendimiento objetivo: 40 qq/ha; densidad: 5,500 plantas/ha; altitud: 1,400 m
- Etapa: expansión rápida (f_e_N = 0.35, f_e_P = 0.30, f_e_K = 0.35)
- D_c_N = 40 × 135 × 1.05 × 0.35 = 1,984.5 kg-nutriente/ha ÷ ciclo → ajustar a kg/ha para etapa
- Resultado típico: DAP 80 kg/ha + Urea 60 kg/ha + KCl 45 kg/ha → ≈ 2.5 oz Urea/planta

### Ejemplo B — Laboratorio, Catuaí en llenado, pH 4.8

- pH < 5.0 → bloquear fertilizantes solubles
- Recomendar 800 kg/ha de cal dolomítica primero
- Reprogramar aplicación de N-P-K en 60 días

---

## 15. Validación y hoja de ruta

### Validación mínima antes de producción

- [ ] Comparar 10 recomendaciones del motor con recomendaciones de agrónomo local
- [ ] Verificar conversión de unidades con datos reales de laboratorio
- [ ] Ajustar factores varietales con datos de al menos 2 fincas por variedad
- [ ] Calibrar sensor 7 en 1 con muestras de laboratorio paralelas (mínimo 20 pares)

### Hoja de ruta de mejoras

| Versión | Mejora |
|---|---|
| v1.0 | Motor base con café y maíz; factores varietales en 1.00 |
| v1.1 | Calibración local de factores varietales por zona |
| v1.2 | Integración de maíz con calendario local nicaragüense |
| v2.0 | Optimización por programación lineal (LP solver) |

---

## 16. Limitaciones y conclusiones

- Los umbrales de Cenicafé fueron desarrollados para Colombia y deben tratarse como "referencia transferida" hasta validación local.
- El sensor 7 en 1 no reemplaza el análisis de laboratorio para Ca, Mg, S, micronutrientes ni CIC.
- El modelo fenológico de cohortes requiere que el usuario registre las fechas de floración; sin este dato, la clasificación se basa solo en el calendario.
- El fraccionamiento propuesto es orientativo; las condiciones locales de lluvia, temperatura y acceso pueden requerir ajustes.

---

## 17. Referencias

- Asociación Nacional del Café [Anacafé]. (s. f.). *Manejo agronómico del cafeto*. Anacafé.
- Cenicafé. (2013). *Manual del cafetero colombiano: Investigación y tecnología para la sostenibilidad de la caficultura* (Vol. 2). Centro Nacional de Investigaciones de Café.
- Instituto del Café de Costa Rica [ICAFE]. (s. f.). *Guía técnica para el cultivo del café*. ICAFE.
- Instituto Hondureño del Café [IHCAFE]. (s. f.). *Recomendaciones de fertilización para café en Honduras*. IHCAFE.
- Moraga, J. (2024). *Guía técnica para el manejo del café en fincas del centro-norte de Nicaragua*. [Publicación técnica regional].
- Sadeghian, S. (2009). *Fertilidad del suelo y nutrición del café en Colombia: Guía práctica*. Cenicafé.
- Sadeghian, S. (2018). *Interpretación del análisis de suelos para el cultivo de café*. Cenicafé, Avances Técnicos, (494).
- Sadeghian, S. (2020). *Actualización de niveles críticos de nutrientes para café en Colombia*. Cenicafé.
- Salazar-Gutiérrez, M. R., Chaves-Córdoba, B., & Arcila-Pulgarín, J. (1993). Desarrollo del fruto del café. *Cenicafé*, 44(1), 33–44.
- World Coffee Research. (s. f.-a). *Caturra variety profile*. World Coffee Research Variety Catalog. https://varieties.worldcoffeeresearch.org/varieties/caturra
- World Coffee Research. (s. f.-b). *Bourbon variety profile*. World Coffee Research Variety Catalog. https://varieties.worldcoffeeresearch.org/varieties/bourbon
- World Coffee Research. (s. f.-c). *Catuaí variety profile*. World Coffee Research Variety Catalog. https://varieties.worldcoffeeresearch.org/varieties/catuai
