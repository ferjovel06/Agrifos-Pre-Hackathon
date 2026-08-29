# AGRIFOS

## Etapa fenológica y motor matemático de fertilización para café

## Documento técnico de investigación y especificación para implementación

## Variedades consideradas: Caturra, Borbón y Catuaí

## Contexto de uso: fincas cafetaleras de Nicaragua y Centroamérica

## Versión 1.0 | 25 de agosto de 2026

Elaborado para orientar el desarrollo del módulo de análisis agronómico de Agrifos.

## Resumen

Este documento presenta una propuesta técnica para que Agrifos determine la etapa fenológica del cafeto y genere recomendaciones de fertilización a partir de datos de edad del cultivo, calendario, altitud, observaciones de floración, lecturas de un sensor siete en uno y análisis de laboratorio. La propuesta se construye alrededor de tres variedades de Coffea arabica L. contempladas en el proyecto: Caturra, Borbón y Catuaí. La evidencia principal procede de Cenicafé, World Coffee Research y una guía técnica validada en fincas del centro-norte de Nicaragua. Se adopta un enfoque híbrido: la edad en meses clasifica el ciclo de vida; la fecha de floración determina la edad del fruto; la altitud ajusta la duración esperada; y el color o estado observado del fruto confirma la madurez antes de recomendar cosecha. Para fertilización, se evita restar directamente todo el resultado de laboratorio a la demanda del cultivo, porque P, K, N y S dependen del método analítico, la mineralización, la capacidad de intercambio y la respuesta local. El motor propuesto convierte unidades, valida calidad de datos, interpreta niveles críticos calibrados, estima demanda por rendimiento y estado fenológico, y resuelve una combinación de fertilizantes mediante programación lineal. Se incluyen fórmulas, tablas de implementación, esquema de datos, pseudocódigo, escenarios de recomendación y un protocolo de calibración local antes de convertir el sistema en una prescripción agronómica automática.

Palabras clave: café, Coffea arabica, fenología, fertilización, análisis de suelo, Caturra, Borbón, Catuaí, Nicaragua.

### Advertencia de uso

Los rangos y ecuaciones de este documento son una especificación inicial para software y apoyo a la decisión. No sustituyen un análisis de laboratorio, la validación de un agrónomo ni un ensayo local de respuesta. Las publicaciones de Cenicafé son una referencia regional sólida, pero sus niveles críticos fueron calibrados principalmente en Colombia; por ello, Agrifos debe etiquetar como “referencia transferida” cualquier umbral que todavía no haya sido calibrado en Nicaragua (Sadeghian, 2009, 2020).

## Contenido y decisiones de diseño

## 1. Alcance y fuentes de evidencia

## 2. Variedades y diferencias agronómicas

## 3. Modelo de etapa fenológica

## 4. Calendario anual para Nicaragua

## 5. Datos y reglas de implementación fenológica

## 6. Necesidades nutricionales del cafeto

## 7. Normalización de unidades y calidad de datos

## 8. Interpretación del análisis de laboratorio

## 9. Ruta del sensor siete en uno

## 10. Motor matemático de fertilización

## 11. Catálogo de fertilizantes

## 12. Optimización de dosis y fraccionamiento

## 13. Salidas para la aplicación

## 14. Ejemplos de cálculo

## 15. Validación y hoja de ruta

## 16. Limitaciones y conclusiones

## 17. Referencias

## Apéndices. Tablas y contratos de datos

## Resumen ejecutivo

La aplicación debe responder dos preguntas diferentes: “¿en qué etapa de vida está la planta?” y “¿en qué etapa está el fruto de esta floración?”. La primera depende de los meses desde el trasplante; la segunda depende de los días desde floración. Una parcela puede tener varias floraciones y, por tanto, simultáneamente frutos en cuajado, llenado y maduración. El modelo no debe guardar una sola etapa rígida para toda la parcela.

Ciclo de vida: vivero, establecimiento, levante, primera producción y producción estable.

Fenología reproductiva: prefloración, floración, cuajado, expansión, llenado, maduración y cosecha.

Prioridad de evidencia: observación de floración y fruto > registro de lluvia/humedad > calendario mensual.

Ruta de laboratorio: interpretación completa de pH, materia orgánica, CIC, textura, N, P, K, Ca, Mg y S; añadir Al intercambiable o acidez de reserva para calcular encalado.

Ruta de sensor: diagnóstico preliminar de pH, humedad, temperatura, CE, N, P y K; sin recomendar cal, Ca, Mg, S u orgánicos sin datos adicionales.

Fertilizantes: urea, DAP y KCl permanecen como opciones, pero se agregan MAP, TSP, sulfato de amonio, sulfato de potasio, nitrato de potasio, nitrato de calcio, kieserita, yeso, cal dolomítica y fórmulas NPK.

## 1. Alcance y fuentes de evidencia

El alcance corresponde a un módulo de apoyo a decisiones para parcelas de café arábica. El módulo debe trabajar con la información disponible en el repositorio Agrifos: variedad, edad, parcela, lecturas de sensor, parámetros de laboratorio y registros fenológicos. El objetivo no es crear una tabla universal que funcione igual en todos los suelos, sino establecer una línea base transparente que pueda actualizarse con resultados de parcelas nicaragüenses.

### 1.1 Jerarquía de fuentes

| Nivel | Fuente | Uso en Agrifos |
| --- | --- | --- |
| 1 | Ensayo local y recomendación de laboratorio | Umbrales y dosis definitivas por región, método y cultivo. |
| 2 | Guía validada en centro-norte de Nicaragua | Calendario operativo, prácticas de finca y contexto regional (Moraga, 2024). |
| 3 | Cenicafé | Fenología, extracción de nutrientes, calibración de análisis y fertilización por etapas. |
| 4 | World Coffee Research | Rasgos comparativos de Caturra, Borbón y Catuaí; no reemplaza calibración nutricional local. |
| 5 | Literatura general | Conversión de unidades, formulación y restricciones químicas. |

Nota. Las recomendaciones generales de fertilización de Cenicafé se desarrollaron para condiciones colombianas y deben mostrarse en la aplicación con la etiqueta “referencia regional”.

### 1.2 Principio de trazabilidad

Cada resultado de Agrifos debe guardar la fuente de cada umbral: método de laboratorio, publicación, fecha de calibración, región, variedad, nivel de confianza y versión del motor. Así, la app puede explicar por qué clasificó un dato como bajo, adecuado o alto y permite sustituir los valores de referencia por datos de ensayos locales sin reescribir el software.

## 2. Variedades y diferencias agronómicas

Las tres variedades pertenecen al grupo de café arábica usado en Centroamérica. World Coffee Research describe Caturra y Catuaí como plantas compactas, con potencial de rendimiento medio a alto, requerimiento nutricional alto y maduración promedio; Borbón se describe como planta alta, de requerimiento nutricional medio y maduración temprana (World Coffee Research, s. f.-a, s. f.-b, s. f.-c). La guía nicaragüense también identifica Caturra y Catuaí entre los materiales compactos de interés regional (Moraga, 2024).

## Tabla 1. Perfil de las tres variedades contempladas en Agrifos

| Variedad | Arquitectura | Primer año de producción* | Nutrición relativa | Maduración | Densidad de referencia |
| --- | --- | --- | --- | --- | --- |
| Caturra | Compacta | Año 3 | Alta | Promedio | 5,000–6,000 plantas/ha |
| Borbón | Alta | Año 4 | Media | Temprana | 3,000–4,000 plantas/ha |
| Catuaí | Compacta | Año 3 | Alta | Promedio | 5,000–6,000 plantas/ha |

Nota. *El año de primera producción es un valor de referencia genética y de manejo; el inicio real puede variar por vivero, altitud, estrés, poda, densidad y fecha de siembra. La “nutrición relativa” no debe convertirse automáticamente en un multiplicador fijo de dosis.

### 2.1 Cómo modelar la variación entre variedades

La diferencia varietal debe entrar al motor mediante variables observables: densidad, carga de fruto, rendimiento objetivo, edad, vigor y clase de maduración. No se recomienda aplicar factores arbitrarios como 1.05 para una variedad y 1.10 para otra sin datos de campo. El motor inicia con factor varietal 1.00 y utiliza la información de WCR para advertencias de manejo; después puede aprender un factor calibrado por variedad y zona.

Demanda ajustada = demanda base × factor de densidad × factor de carga × factor de edad × factor calibrado de variedad

En esta versión, el factor calibrado de variedad se mantiene en 1.00 por defecto y se registra como parámetro pendiente de validación. Borbón puede adelantar la ventana de maduración como clase “temprana”, pero no se fija una cantidad de días universal sin un conjunto local de fechas de floración y cosecha.

## 3. Modelo de etapa fenológica

El desarrollo del fruto desde floración hasta maduración dura en promedio 32 semanas. En zonas por debajo de 1,200 m puede durar 28–30 semanas; por encima de 1,700 m, 34–36 semanas. Cenicafé divide el proceso en una primera etapa de crecimiento lento hasta la semana 8, una segunda de crecimiento rápido entre las semanas 9 y 26 y una tercera de cambio de color y madurez fisiológica entre las semanas 27 y 32 (Salazar-Gutiérrez et al., 1993).

## Tabla 2. Estados fenológicos del fruto para el motor

| Estado | Días desde floración | Señal biológica | Decisión en la app |
| --- | --- | --- | --- |
| Prefloración | Antes del día 0 | Yemas diferenciadas; respuesta a periodo seco y primeras lluvias. | Avisar preparación de floración y revisar nutrición equilibrada. |
| Floración | 0–7 | Flores abiertas; fecha de evento registrada. | Crear cohorte de floración y comenzar contador DAF. |
| Cuajado / “cabeza de fósforo” | 8–56 | Fruto verde pequeño; crecimiento lento. | Evitar interpretar como falta de cosecha; priorizar humedad y sanidad. |
| Expansión rápida | 57–120 | Aumento de tamaño y peso; alta demanda de agua y N/K. | Programar fraccionamiento; vigilar estrés hídrico. |
| Llenado y endurecimiento | 121–182 | Se forma y endurece el endospermo; cambia la relación agua/materia seca. | Ajustar K y balance; evitar exceso de N tardío. |
| Maduración fisiológica | 183–224 típico | Cambio de verde a rojo o amarillo según material. | Iniciar cosecha selectiva si la observación confirma color. |
| Ventana tardía por altitud | 225–252 | Maduración retrasada en zonas altas o por clima. | Mantener monitoreo; no declarar listo solo por calendario. |

Nota. DAF = días after flowering, traducido aquí como días desde floración. La ventana de maduración se ajusta por altitud y se confirma con observación. “Listo para cosecha” requiere color de cereza y criterio de calidad, no solamente el número de días.

### 3.1 Edad de la planta en meses

| Edad aproximada | Etapa de vida | Indicadores | Regla inicial para la app |
| --- | --- | --- | --- |
| 0–3 meses | Vivero inicial | Plántula, hojas cotiledonares y primeras hojas verdaderas. | No emitir dosis productiva; registrar riego, sustrato y sanidad. |
| 4–8 meses | Vivero avanzado | Sistema radical y tallo en formación. | Nutrientes fraccionados; evitar salinidad y sobredosis. |
| 9–12 meses | Establecimiento | Trasplante, adaptación y emisión de hojas nuevas. | Estado “establecimiento”; priorizar humedad y P de arranque. |
| 13–24 meses | Levante | Crecimiento vegetativo; formación de ramas y bandolas. | Plan de N; P más importante al inicio; K y Mg aumentan con edad. |
| 25–36 meses | Transición a producción | Puede aparecer primera cosecha en Caturra/Catuaí. | Separar demanda vegetativa y demanda de fruto. |
| 37–48 meses | Producción inicial | Producción más regular; Borbón puede iniciar alrededor del año 4. | Usar rendimiento objetivo y carga observada. |
| >48 meses | Producción estable | Ciclos anuales, podas y renovación de ramas. | Usar balance anual, análisis de suelo y extracción por cosecha. |

Nota. Los cortes mensuales son reglas de software, no límites fisiológicos rígidos. Deben parametrizarse por vivero, fecha de trasplante, altitud y manejo.

## 4. Calendario anual de referencia para Nicaragua

La guía técnica validada en fincas de la zona centro-norte de Nicaragua indica que la activación y diferenciación de yemas productivas se relaciona con el periodo seco, las lluvias y el manejo de sombra; también señala que las ramas nuevas se forman principalmente entre febrero y septiembre y que el ciclo productivo comprende prefloración, floración, postfloración, crecimiento/llenado y maduración (Moraga, 2024). Por la variabilidad de Nicaragua, el calendario debe ser un “prior” regional y no la única fuente de decisión.

## Tabla 3. Calendario inicial configurable por mes

| Mes | Etapa predominante esperada | Actividad de Agrifos | Confianza |
| --- | --- | --- | --- |
| Enero | Cosecha tardía, postcosecha y vegetativo | Registrar cosecha, poda, sombra, suelo y recuperación. | Media |
| Febrero | Postcosecha y crecimiento vegetativo | Actualizar edad, vigor, sombra y fertilidad; preparar muestreo. | Media |
| Marzo | Prefloración / primeras floraciones | Registrar fecha exacta de cada floración; no usar un único evento. | Baja–media |
| Abril | Floración y cuajado | Crear cohortes; controlar humedad y eventos de lluvia. | Media |
| Mayo | Cuajado y expansión temprana | Revisar supervivencia de frutos y fraccionar nutrientes. | Media |
| Junio | Expansión rápida | Monitorear agua, N, K y vigor de ramas. | Media |
| Julio | Expansión y transición a llenado | Registrar estado de fruto por muestreo. | Media |
| Agosto | Llenado y endurecimiento inicial | Evitar exceso de N; revisar K, Mg y humedad. | Media |
| Septiembre | Llenado y nuevas ramas | Actualizar cohortes; ajustar por altitud y lluvia. | Media |
| Octubre | Maduración en zonas tempranas | Cosecha selectiva donde el color lo confirme. | Media |
| Noviembre | Maduración y cosecha principal | Activar alerta de cosecha; controlar frutos sobremaduros. | Media–alta |
| Diciembre | Cosecha, postcosecha y prefloración siguiente | Cerrar balance de rendimiento y nutrientes extraídos. | Media |

Nota. Este calendario debe tener configuración por departamento, municipio, altitud y patrón de lluvias. El sistema debe permitir registrar más de una floración en el mismo año.

### 4.1 Ajuste por altitud

| Altitud | Duración de referencia floración–madurez | Regla de cálculo |
| --- | --- | --- |
| <1,200 m | 196–210 días | Ventana rápida; revisar cosecha desde DAF 183. |
| 1,200–1,700 m | 224 días aproximadamente | Ventana base; revisar desde DAF 196–224. |
| >1,700 m | 238–252 días | Ventana lenta; no declarar madurez antes de observación. |

## 5. Datos y reglas de implementación fenológica

El módulo fenológico debe operar con cohortes. Una cohorte es un conjunto de flores o frutos originados por un evento de floración observado en una fecha determinada. Para cada cohorte se almacenan fecha, porcentaje estimado de plantas o bandolas afectadas, variedad, altitud, observación de color y nivel de confianza.

### 5.1 Algoritmo de clasificación

$$
\mathrm{DAF} = \mathrm{fecha}_{actual} - \mathrm{fecha}_{floración}
$$

$$
\mathrm{madurez}_{esperada} = 224\ \text{días} + \mathrm{ajuste}_{altitud} + \mathrm{ajuste}_{variedad}
$$

El ajuste por altitud toma valores aproximados de −14 a −28 días en zonas bajas y +14 a +28 días en zonas altas, siempre como ventana y no como fecha exacta. El ajuste varietal se mantiene en cero para Caturra y Catuaí en la versión inicial; Borbón se etiqueta como maduración temprana y puede recibir un ajuste configurable solo después de validar datos locales.

Si existe una floración observada en los últimos 365 días, usarla como fecha principal.

Si no existe floración observada, usar lluvia acumulada y calendario regional como estimación de baja confianza.

Si hay varias cohortes, calcular el estado dominante ponderado por proporción de frutos.

Si DAF supera la ventana esperada pero el fruto sigue verde, marcar “maduración retrasada” y solicitar revisión.

Solo marcar “listo para cosecha” cuando DAF esté dentro de la ventana y una observación de color confirme madurez.

### 5.2 Pseudocódigo

```python
def etapa_fenologica(planta, fecha_actual):
    edad = meses_desde(planta.fecha_trasplante, fecha_actual)
    ciclo = clasificar_ciclo_vida(edad, planta.variedad)
    cohortes = obtener_cohortes(planta.parcela)

    if not cohortes:
        return ciclo, "sin_evento_floracion", confianza="baja"

    estados = []
    for cohorte in cohortes:
        daf = dias_entre(cohorte.fecha_floracion, fecha_actual)
        ventana = ventana_por_altitud(planta.altitud_m)
        estado = clasificar_por_daf(daf, ventana)
        estado = confirmar_con_observacion(estado, cohorte.color_fruto)
        estados.append((estado, cohorte.peso))

    dominante = promedio_ponderado(estados)
    return ciclo, dominante.estado, dominante.confianza
```

## 6. Necesidades nutricionales del cafeto

La fertilización debe cubrir crecimiento vegetativo, formación de raíces, floración, crecimiento del fruto, renovación de ramas y reposición de nutrientes exportados. La demanda no es constante durante el año. En la etapa de levante, Cenicafé recomienda N en todas las aplicaciones, P relativamente mayor al inicio, K creciente hacia los 18 meses y Mg desde aproximadamente los 10 meses (Sadeghian & González-Osorio, 2012). En producción, el K adquiere importancia durante llenado y maduración, mientras que un exceso de N tardío puede favorecer vegetación y retrasar la maduración.

## Tabla 4. Prioridad funcional por etapa

| Etapa | N | P | K | Ca/Mg/S | Aplicación |
| --- | --- | --- | --- | --- | --- |
| Vivero | Media | Media | Baja | Baja–media | Fraccionar; proteger raíces y evitar CE alta. |
| Establecimiento | Media | Alta | Baja–media | Media | P de arranque y materia orgánica analizada. |
| Levante temprano | Alta | Media–alta | Media | Mg según análisis | N frecuente; P para raíz y estructura. |
| Levante tardío | Alta | Media | Media–alta | Mg y S | Preparar ramificación y primera producción. |
| Floración/cuajado | Media | Media | Alta | Ca y B requieren diagnóstico | Evitar estrés hídrico; no sobredosificar. |
| Expansión/llenado | Media | Media | Alta | Mg/S según laboratorio | Fraccionar K y N; coordinar con lluvia. |
| Maduración/cosecha | Baja–media | Baja | Media–alta | Balance | Evitar N excesivo; cosechar selectivamente. |

### 6.1 Referencia de levante

Cuando no se dispone de análisis de suelo, Cenicafé presenta una guía general acumulada por planta: 58 g de N, 15 g de P₂O₅, 15 g de K₂O y 5 g de MgO entre aplicaciones a los 2, 6, 10, 14 y 18 meses. La misma fuente muestra equivalentes aproximados de 114 g de urea, 33 g de DAP, 25 g de KCl y 5 g de MgO, pero advierte que se trata de una alternativa general para levante y no de una receta universal. Agrifos debe mostrarla como “plan de respaldo sin análisis”, con límites y advertencia.

## 7. Normalización de unidades y calidad de datos

La app debe guardar el valor original, la unidad original, el método analítico y el valor normalizado. No es suficiente convertir “ppm” a “mg/kg” sin verificar que el laboratorio esté reportando una concentración de masa. En fertilidad de suelos, pH es adimensional; materia orgánica y N total se expresan en porcentaje; P, S y micronutrientes en mg/kg; K, Ca y Mg intercambiables en cmolc/kg; CIC en cmolc/kg; CE en dS/m.

## Tabla 5. Unidades canónicas y conversiones

| Dato | Unidad canónica | Conversión / fórmula | Observación |
| --- | --- | --- | --- |
| pH | adimensional | sin conversión | Registrar relación suelo:agua. |
| Materia orgánica | % | g/kg ÷ 10 | No confundir con carbono orgánico. |
| P y S disponibles | mg/kg | 1 ppm ≈ 1 mg/kg | Registrar extractante. |
| K intercambiable | cmolc/kg | mg/kg ÷ 390.98 | Si viene en mg/kg, convertir antes de interpretar. |
| Ca intercambiable | cmolc/kg | mg/kg ÷ 200.39 | Valor de carga intercambiable. |
| Mg intercambiable | cmolc/kg | mg/kg ÷ 121.53 | Valor de carga intercambiable. |
| CIC | cmolc/kg | meq/100 g = cmolc/kg | Equivalencia numérica. |
| CE | dS/m | mS/cm = dS/m; µS/cm ÷ 1000 = dS/m | Registrar temperatura de medición. |
| P₂O₅ | kg/ha | P × 2.291 | Usar solo para expresar fertilizante. |
| K₂O | kg/ha | K × 1.205 | Usar solo para expresar fertilizante. |

Fuente de conversiones: Sadeghian (2020). Las conversiones de elemento a óxido no representan disponibilidad en el suelo; solo normalizan la etiqueta de fertilizantes.

### 7.1 Control de calidad mínimo

Rechazar valores fuera de límites físicos: pH < 2 o > 10, CE negativa, humedad fuera de 0–100 %, concentraciones negativas.

Solicitar método de extracción para P, K, Ca, Mg y S; sin método, bajar confianza y evitar umbral rígido.

Verificar fecha de muestreo y que la aplicación reciente de fertilizante no sesgue la muestra.

En sensor, tomar 3–5 lecturas por zona y almacenar mediana y dispersión.

No mezclar datos de suelo superficial y subsuperficial sin registrar profundidad.

## 8. Interpretación del análisis de laboratorio

La interpretación debe ser condicional al método analítico. Cenicafé muestra que los niveles críticos y de suficiencia de P, K y Mg se calibran con experimentos de respuesta. En una referencia colombiana, los niveles críticos fueron P 11–21 mg/kg, K 0.20–0.30 cmolc/kg y Mg 0.20–0.50 cmolc/kg; el nivel de suficiencia fue P 30.1–32.5 mg/kg y K 0.43–0.48 cmolc/kg (Sadeghian, 2009). Estos rangos deben iniciar como referencia regional y reemplazarse con calibración Nicaragua–método.

## Tabla 6. Umbrales iniciales de interpretación para la app

| Parámetro | Unidad | Bajo / posible deficiencia | Adecuado de referencia | Alto / posible exceso | Condición |
| --- | --- | --- | --- | --- | --- |
| pH | adimensional | <5.0 | 5.0–5.5 | >5.5 | No define encalado sin Al/acidez de reserva. |
| Materia orgánica | % | <8 | 8–16 | >16 | Referencia Cenicafé; depende de clima y textura. |
| N total | % | <0.34 | 0.34–0.58 | >0.58 | No equivale a N disponible inmediato. |
| P disponible | mg/kg | <10 | 10–20 | >20 | Método debe coincidir con calibración. |
| S disponible | mg/kg | <6 | 6–12 | >12 | Alta incertidumbre sin método. |
| K intercambiable | cmolc/kg | <0.20 | 0.20–0.40 | >0.40 | No es inventario total de K. |
| Ca intercambiable | cmolc/kg | <1.5 | 1.5–3.0 | >3.0 | Revisar saturación y pH. |
| Mg intercambiable | cmolc/kg | <0.6 | 0.6–0.9 | >0.9 | Revisar relación K:Mg. |
| CIC | cmolc/kg | <15 | 15–25 | >25 | Interpretar junto a textura y MO. |
| CE | dS/m | — | <1.0 usualmente sin salinidad | >1.0 revisar sales | Umbral depende del extracto y humedad. |

Nota. “Bajo”, “adecuado” y “alto” son categorías de referencia para clasificación inicial, no dosis automáticas. Sadeghian (2020) enfatiza que el método, las unidades, el muestreo y las relaciones entre bases deben revisarse antes de interpretar.

### 8.1 Lo que falta para recomendar cal

Con pH y CIC solamente no se debe calcular una dosis segura de cal. Se requiere acidez intercambiable, Al intercambiable y/o pH buffer, además de poder neutralizante del producto. Si estos datos no existen, el motor debe devolver: “pH ácido: solicitar prueba de acidez de reserva y Al intercambiable antes de recomendar encalado”. La cal dolomítica puede aportar Ca y Mg, pero la dosis depende de la acidez que se desea neutralizar.

## 9. Ruta del sensor siete en uno

El sensor del proyecto reporta N, P, K, pH, humedad, temperatura y conductividad eléctrica. Las lecturas de NPK en sensores económicos suelen depender de humedad, textura, salinidad, temperatura y calibración del equipo; por ello deben utilizarse inicialmente como diagnóstico de tendencia, no como sustituto de un laboratorio acreditado. La app debe mostrar una puntuación de confianza y sugerir confirmación por laboratorio cuando el resultado implique una dosis alta.

## Tabla 7. Uso recomendado de cada variable del sensor

| Variable | Uso directo | Limitación | Salida recomendada |
| --- | --- | --- | --- |
| pH | Clasificar acidez aproximada | Electrodos requieren calibración y mantenimiento. | Alerta orientativa; confirmar en laboratorio. |
| Humedad | Riego y contexto de disponibilidad | No es disponibilidad nutricional. | Ajustar confianza y calendario de aplicación. |
| Temperatura | Contexto de actividad radicular | No determina por sí sola demanda. | Usar como covariable fenológica. |
| CE | Riesgo de salinidad y concentración iónica | No identifica qué nutriente causa la CE. | Bloquear sobrefertilización si CE alta. |
| N | Tendencia de N medido | Calibración muy dependiente del suelo. | Diagnóstico preliminar, no dosis plena. |
| P | Tendencia de P | Extracción y humedad afectan lectura. | Confirmar si aparece deficiencia. |
| K | Tendencia de K | Confusión con otros iones y CE. | Usar para priorizar laboratorio. |

### 9.1 Regla de confianza

$$
C_{sensor} = 0.25C_{calibración} + 0.25C_{repetibilidad} + 0.20C_{humedad} + 0.15C_{CE} + 0.15C_{laboratorio}
$$

La fórmula anterior es una propuesta de software y debe calibrarse. Mientras la aplicación no tenga curvas propias por tipo de suelo, la salida de sensor debe limitarse a recomendaciones de bajo riesgo: revisar laboratorio, fraccionar dosis, evitar aplicaciones con CE alta y priorizar observación de síntomas. No se debe recomendar encalado, Ca, Mg, S, micronutrientes u orgánicos únicamente con el sensor siete en uno.

## 10. Motor matemático de fertilización

El motor combina cuatro componentes: demanda del cultivo, crédito del suelo, eficiencia de recuperación y selección de productos. La demanda se expresa en kg/ha de elemento o de óxido según la etiqueta. El resultado se convierte después a kg/ha, kg/manzana y g/planta.

### 10.1 Demanda por extracción

Cenicafé estimó que una cosecha equivalente a 1,000 kg de café almendra con 11 % de humedad extrae aproximadamente 30.9 kg de N, 2.3 kg de P, 36.9 kg de K, 4.3 kg de Ca, 2.3 kg de Mg y 1.2 kg de S. Estos datos sirven para estimar la reposición exportada; no son la totalidad de la demanda anual de una planta, porque también existe crecimiento vegetativo, raíces, ramas y reciclaje de hojarasca (Sadeghian et al., 2006/2007).

$$
E_i = \frac{Y_{verde}}{1000}\,c_i
$$

Para llevar los datos elementales a las unidades de etiqueta: P₂O₅ = P × 2.291 y K₂O = K × 1.205. El rendimiento objetivo debe ser editable y preferiblemente expresarse como kg de café verde por hectárea. Si el productor entrega café cereza, Agrifos debe exigir un factor de conversión local o marcar el cálculo como estimado.

### 10.2 Crédito del suelo

El crédito del suelo no debe calcularse como “mg/kg × masa del suelo” para todos los nutrientes. Ese procedimiento puede sobreestimar P y K porque las pruebas de suelo son índices calibrados de disponibilidad, no inventarios completos que la planta pueda extraer durante el ciclo. La app debe mapear cada resultado a una categoría calibrada: deficiente, respuesta probable, suficiente o alto. A partir de la categoría, una tabla de respuesta entrega un crédito o una reducción porcentual configurada por región y método.

$$
R_i = \frac{D_i\left(1-C_i\right)}{\eta_i}
$$

Para N y S, el crédito se puede estimar con materia orgánica, N mineral, historial de abonos y cobertura, pero la mineralización es incierta. Para Ca, Mg y acidez se utilizan cationes intercambiables, saturaciones y acidez de reserva. Cada eficiencia debe ser configurable por fuente, textura, pendiente, lluvia y método de aplicación.

### 10.3 Masa de suelo para datos mineralizados

$$
M_{suelo}\,[\mathrm{kg/ha}] = 10{,}000\,z\,[\mathrm{m}]\,\rho_b\,[\mathrm{Mg/m^3}]\,1000
$$

Esta ecuación es útil para convertir una concentración de N mineral realmente medida en kg/ha dentro de una profundidad definida. No debe utilizarse para transformar automáticamente P disponible o K intercambiable en una “reserva fertilizante” sin una calibración de extracción y absorción.

## 11. Catálogo de fertilizantes y alternativas

El catálogo debe almacenar el grado garantizado por el fabricante, no un valor fijo universal. Los grados siguientes son valores típicos de referencia y deben verificarse con la etiqueta comercial disponible en Nicaragua.

## Tabla 8. Catálogo inicial de productos

| Producto | Grado típico N–P₂O₅–K₂O | Aporte adicional | Uso preferente | Precaución |
| --- | --- | --- | --- | --- |
| Urea | 46–0–0 | — | N de alta concentración | Pérdidas por volatilización si queda superficial y sin lluvia. |
| DAP | 18–46–0 | — | N + P de arranque | Puede subir pH local; no usar como único producto permanente. |
| MAP | 11–52–0 | — | P con menor N | Adecuado si se requiere P sin tanto N. |
| TSP | 0–46–0 | — | P sin N | Útil si N ya es suficiente. |
| Sulfato de amonio | 21–0–0 | ≈24 % S | N + S | Acidificante; revisar pH y CE. |
| KCl | 0–0–60 | Cl⁻ | K económico | Evitar si CE o cloruros altos; revisar calidad. |
| Sulfato de potasio | 0–0–50 | ≈17–18 % S | K con bajo cloruro | Más costoso; útil con restricción de Cl. |
| Nitrato de potasio | 13–0–46 | — | K soluble + N nítrico | Costo y manejo; apropiado en fertirriego si es compatible. |
| Nitrato de calcio | ≈15.5–0–0 | ≈19 % Ca | N + Ca | Grado depende de etiqueta; incompatibilidad con fosfatos concentrados. |
| Kieserita | 0–0–0 | Mg + S | Mg y S | Verificar análisis del producto. |
| Yeso agrícola | 0–0–0 | Ca + S | Ca/S sin subir mucho el pH | No sustituye cal para neutralizar acidez. |
| Cal dolomítica | 0–0–0 | Ca + Mg; poder neutralizante | Acidez y aporte de bases | Requiere Al/acidez de reserva y análisis del material. |
| Fórmula NPK | Variable | Puede incluir Mg, S, Zn, B | Plan integrado | Nunca asumir el grado sin etiqueta. |

Nota. Las mezclas y compatibilidades dependen de solubilidad, humedad, granulometría y aplicación. El motor debe tratar el grado del producto como dato configurable.

## 12. Optimización de dosis y fraccionamiento

Una vez estimado el requerimiento de nutrientes, Agrifos selecciona productos que cubran la demanda con bajo costo, bajo riesgo de salinidad y menor excedente. La formulación se puede representar como un problema de programación lineal.

$$
\min_x\; costo(x) + \lambda_1\,déficit(x) + \lambda_2\,exceso(x) + \lambda_3\,riesgo_{cloruro}(x)
$$

$$
\text{sujeto a}\quad A x + u - o = R,\qquad x \ge 0,\qquad x \le x_{máximo\ por\ aplicación}
$$

En estas expresiones, x es el vector de kg/ha de cada producto, A contiene las fracciones de N, P₂O₅, K₂O, Ca, Mg y S, u y o son déficit y exceso penalizados, y λ representa prioridades. Con Python, el backend puede usar scipy.optimize.linprog; si la dependencia no está disponible, se puede usar una búsqueda voraz con límites y advertencia de menor optimalidad.

### 12.1 Restricciones agronómicas

No aplicar una dosis completa anual en una sola fecha; fraccionar de acuerdo con lluvia, etapa y textura.

Limitar N por aplicación según edad, humedad, riesgo de lixiviación y recomendación del agrónomo.

Penalizar KCl cuando CE sea alta, exista historial de cloruros o se haya configurado producción de calidad con bajo cloruro.

No aplicar cal junto con urea o fuentes amoniacales sin regla de separación temporal.

No mezclar concentrados incompatibles, especialmente calcio con fosfatos o sulfatos en solución.

Convertir kg/ha a kg/manzana usando 1 manzana = 0.7042 ha como valor configurable para Nicaragua.

$$
\mathrm{kg/manzana} = \mathrm{kg/ha}\times 0.7042
$$

$$
\mathrm{g/planta} = \frac{\mathrm{kg/ha}\times 1000}{\mathrm{plantas/ha}}
$$

### 12.2 Fraccionamiento propuesto

| Momento | Proporción del plan anual | Prioridad | Regla |
| --- | --- | --- | --- |
| Prefloración / inicio de lluvias | 20–30 % | N equilibrado, P/K según análisis | Aplicar solo con humedad suficiente. |
| Cuajado y expansión inicial | 25–35 % | N + K; P si es bajo | Evitar salinidad alrededor del tallo. |
| Llenado | 25–35 % | K + N moderado + Mg/S si corresponde | Reducir N si el vigor es excesivo. |
| Postcosecha / recuperación | 10–20 % | N, Ca/Mg/S según diagnóstico | Ajustar a poda y carga del siguiente ciclo. |

## 13. Salidas para la aplicación

El usuario debe recibir una recomendación explicable, no solo un número. La respuesta debe identificar el estado fenológico, la calidad de los datos, los nutrientes limitantes, la dosis por producto, el fraccionamiento y las advertencias.

## Tabla 9. Contrato de salida recomendado

| Campo | Tipo | Descripción |
| --- | --- | --- |
| life_stage | enum | vivero, establecimiento, levante, producción_inicial, producción_estable. |
| fruit_stage | enum | sin_floración, floración, cuajado, expansión, llenado, maduración, cosecha. |
| phenology_confidence | 0–1 | Confianza derivada de fecha observada, DAF, altitud y color. |
| soil_source | enum | sensor, laboratorio, mixto. |
| soil_confidence | 0–1 | Confianza por método, repetibilidad y calibración. |
| limiting_nutrients | array | Nutrientes en categoría baja o respuesta probable. |
| fertilizer_scenarios | array | Economía, bajo cloruro y orgánico/mixto. |
| application_schedule | array | Fecha relativa, producto, kg/ha, kg/manzana y g/planta. |
| warnings | array | CE alta, falta de Al, método ausente, sensor no calibrado, etc. |
| assumptions | array | Rendimiento, densidad, eficiencia y fuente de umbral usadas. |

### 13.1 Esquema JSON de ejemplo

```json
{
  "variety": "Caturra",
  "plant_age_months": 32,
  "altitude_m": 1250,
  "target_green_kg_ha": 1200,
  "phenology": {"fruit_stage": "expansion", "confidence": 0.82},
  "soil": {
    "source": "laboratory",
    "method_p": "Bray II",
    "pH": 5.2,
    "om_pct": 9.4,
    "cec_cmolc_kg": 18.0,
    "p_mg_kg": 8.0,
    "k_cmolc_kg": 0.16,
    "mg_cmolc_kg": 0.42
  },
  "recommendation": {"confidence": 0.68, "scenarios": []},
  "warnings": ["Solicitar Al intercambiable antes de encalar"]
}
```

## 14. Ejemplos de cálculo

### 14.1 Ejemplo hipotético con laboratorio

Supóngase una parcela de Caturra con 1,200 kg de café verde objetivo por hectárea, 5,000 plantas/ha, 1,250 m de altitud, 32 meses de edad, pH 5.2, materia orgánica 9.4 %, CIC 18 cmolc/kg, P 8 mg/kg, K 0.16 cmolc/kg y Mg 0.42 cmolc/kg. El ejemplo es didáctico y no representa una recomendación final para una finca real.

| Paso | Cálculo | Resultado |
| --- | --- | --- |
| 1. Extracción de N | 1.2 × 30.9 | 37.08 kg N/ha |
| 2. Extracción de P | 1.2 × 2.3 × 2.291 | 6.59 kg P₂O₅/ha |
| 3. Extracción de K | 1.2 × 36.9 × 1.205 | 53.37 kg K₂O/ha |
| 4. Interpretación P/K | P <10 y K <0.20 | Respuesta probable a P y K |
| 5. N requerido | Demanda − crédito MO, luego / eficiencia | Se determina por tabla calibrada |
| 6. Cal | pH ácido sin Al/acidez | No calcular; solicitar prueba |

El motor podría ofrecer un escenario con MAP o DAP para corregir P, sulfato de potasio para aportar K con S y urea o sulfato de amonio para N según pH y S. La selección final dependerá de precio, grado real, CE, disponibilidad y restricciones de mezcla. Si el suelo ya presenta CE alta, se penaliza KCl y se divide la dosis.

### 14.2 Ejemplo hipotético con sensor

Con lecturas de pH 5.1, humedad 28 %, temperatura 23 °C, CE 1.3 dS/m y NPK in situ bajos, el motor no debe entregar una dosis plena. La salida correcta es: “probable déficit de NPK, confianza baja; CE elevada; confirmar por laboratorio; evitar aumentar sales; revisar humedad y método de lectura”. Se puede recomendar una inspección de campo y un muestreo compuesto, pero no una dosis de cal o micronutrientes.

## 15. Validación y hoja de ruta

Antes de activar recomendaciones automáticas, Agrifos necesita un piloto con parcelas georreferenciadas de las tres variedades. El piloto debe registrar fecha de floración, fecha de cambio de color, fecha de cosecha, rendimiento verde, manejo de sombra, fertilización, análisis de suelo y lecturas de sensor. El objetivo es ajustar ventanas fenológicas y curvas de respuesta, no solamente comprobar que la app calcula.

## Tabla 10. Protocolo mínimo de validación

| Fase | Muestra mínima sugerida | Qué medir | Criterio de aceptación |
| --- | --- | --- | --- |
| Fenología | ≥10 plantas por parcela; varias parcelas por variedad | Floración, cuajado, color, cosecha, altitud y lluvia | Error de ventana de cosecha documentado y ajustable. |
| Sensor | ≥3 lecturas por punto y día; puntos repetidos | NPK, pH, CE, humedad, temperatura y laboratorio paralelo | Repetibilidad y sesgo cuantificados por tipo de suelo. |
| Laboratorio | Muestra compuesta por parcela y profundidad | Método, pH, MO, CIC, P, K, Ca, Mg, S, Al | Umbral asociado a método y región. |
| Fertilización | Parcelas o franjas con manejo conocido | Dosis, producto, fecha, lluvia, rendimiento y calidad | Respuesta agronómica y económica comparada. |
| Software | Casos normales y extremos | Validación de unidades, límites y explicaciones | Cero recomendaciones sin datos mínimos. |

### 15.1 Hoja de ruta técnica del backend

Fase 1: persistir unidades, método, profundidad, fecha y fuente de cada dato.

Fase 2: implementar clasificación fenológica por cohortes y DAF.

Fase 3: implementar normalizador de laboratorio y categorías de referencia.

Fase 4: implementar catálogo de fertilizantes y cálculo de kg/ha, kg/manzana y g/planta.

Fase 5: añadir optimización lineal, restricciones y escenarios.

Fase 6: calibrar con parcelas de Nicaragua y versionar umbrales.

Fase 7: activar modo “recomendación agronómica” solo después de validación.

## 16. Limitaciones y conclusiones

La principal limitación es la transferencia de umbrales entre países, métodos y suelos. Un valor de P extraído con Bray II no es intercambiable automáticamente con un valor extraído con Olsen o Mehlich. La segunda limitación es la naturaleza indirecta del N y S: la materia orgánica no equivale a liberación inmediata. La tercera es la incertidumbre de sensores NPK económicos. La cuarta es que pH y CIC no bastan para calcular una dosis de cal.

La propuesta sí permite iniciar el desarrollo de Agrifos con seguridad: el sistema puede determinar la etapa de vida por meses, la etapa del fruto por días desde floración, utilizar el calendario nicaragüense como estimación, mostrar diferencias cualitativas entre Caturra, Borbón y Catuaí, normalizar datos de laboratorio, generar diagnósticos transparentes y seleccionar fertilizantes con restricciones. La automatización completa debe quedar condicionada a datos locales, revisión agronómica y versionado de parámetros.

La recomendación central es implementar desde el comienzo el concepto de confianza. Una salida con laboratorio y método conocido puede llegar a confianza alta; una salida basada solo en sensor debe permanecer en confianza baja o media. El usuario debe ver qué dato originó cada recomendación y qué análisis falta para mejorarla.

## 17. Referencias

Acción contra el Hambre. (2024). Guía técnica de producción integral de café: Proyecto fomento de la economía social y el empoderamiento de mujeres rurales en el corredor seco nicaragüense. https://accioncontraelhambre.org.gt/wp-content/uploads/2024/06/GUIA-TECNICA-CAFE-1_compressed.pdf

Moraga, J. M. (2024). Guía técnica de producción integral de café. Acción contra el Hambre y Cooperativa Ríos de Agua Viva 21 de junio R. L. https://accioncontraelhambre.org.gt/wp-content/uploads/2024/06/GUIA-TECNICA-CAFE-1_compressed.pdf

Salazar-Gutiérrez, M. R., Arcila-Pulgarín, J., Riaño-Herrera, N. M., & Bustillo-Pardey, Á. E. (1993). Crecimiento y desarrollo del fruto del café y su relación con la broca. Avances Técnicos Cenicafé, 194, 1–4. https://doi.org/10.38141/10779/0194

Sadeghian, S. (2009). Calibración de análisis de suelo para N, P, K y Mg en cafetales al sol y bajo semisombra. Cenicafé, 60(1), 7–24. https://biblioteca.cenicafe.org/handle/10778/179

Sadeghian, S. (2020). Nutrición de cafetales: Fertilice con mayor eficiencia agronómica y económica. Memorias Seminario Científico Cenicafé, 71(1), e71138. https://doi.org/10.38141/10795/71138

Sadeghian, S., & González-Osorio, H. (2012). Alternativas generales de fertilización para cafetales en la etapa de levante. Avances Técnicos Cenicafé, 423, 1–4. https://doi.org/10.38141/10779/0423

Sadeghian, S., Mejía, B., & Arcila, J. (2006/2007). Composición elemental de frutos de café y extracción de nutrientes por la cosecha en la zona cafetera de Colombia. Cenicafé, 57(4), 251–261. https://biblioteca.cenicafe.org/handle/10778/117

World Coffee Research. (s. f.-a). Bourbon. Varieties Catalog. https://varieties.worldcoffeeresearch.org/varieties/bourbon

World Coffee Research. (s. f.-b). Caturra. Varieties Catalog. https://varieties.worldcoffeeresearch.org/varieties/caturra

World Coffee Research. (s. f.-c). Catuaí. Varieties Catalog. https://varieties.worldcoffeeresearch.org/varieties/catuai

Unigarro-Muñoz, C. A., et al. (2025). Flowering and fruiting of Coffea arabica L.: A comprehensive perspective from phenology. Plants, 14(21), 3396. https://doi.org/10.3390/plants14213396

Uribe-Henao, A. (1977). Constantes físicas y factores de conversión en café. Avances Técnicos Cenicafé, 65, 1–4. https://doi.org/10.38141/10779/0065

República de Nicaragua. (1999). Decreto Ejecutivo 45-99: Regulación del régimen tributario al sector caficultor. La Gaceta. https://nicaragua.justia.com/nacionales/decretos-ejecutivos/regulacion-del-regimen-tributario-al-sector-caficultor-apr-14-1999/gdoc/

## Apéndice A. Parámetros mínimos de parcela

| Campo | Tipo | Obligatorio | Motivo |
| --- | --- | --- | --- |
| variety | enum | Sí | Caturra, Borbón o Catuaí. |
| planting_date | date | Sí | Edad del cultivo. |
| transplant_date | date | Sí | Edad productiva real. |
| altitude_m | number | Sí | Ajuste de duración del fruto. |
| plants_per_ha | number | Sí para dosis | Conversión kg/ha a g/planta. |
| shade_pct | number | Recomendado | Modifica demanda y humedad. |
| target_green_kg_ha | number | Sí en producción | Demanda exportada. |
| soil_depth_cm | number | Sí laboratorio | Interpretación y masa de suelo. |
| bulk_density | number | Recomendado | Conversión de N mineral. |
| flowering_events | array | Sí para fenología | Permite cohortes. |

## Apéndice B. Nutrientes y productos

| Nutriente | Forma de cálculo | Productos principales | Bloqueo o advertencia |
| --- | --- | --- | --- |
| N | Demanda − crédito de mineralización | Urea, DAP, MAP, sulfato de amonio, nitrato de calcio, KNO₃ | Riesgo de volatilización, lixiviación y exceso tardío. |
| P | Categoría calibrada por método | DAP, MAP, TSP, fórmulas NPK | Baja movilidad; incorporar o aplicar en zona radicular. |
| K | Categoría calibrada + extracción | KCl, K₂SO₄, KNO₃ | CE y cloruro; fraccionar. |
| Ca | Saturación/acidez y laboratorio | Nitrato de calcio, yeso, cal | No calcular con sensor ni pH aislado. |
| Mg | Cationes y relación K:Mg | Kieserita, cal dolomítica | Antagonismo con K y necesidad de acidez. |
| S | Método y materia orgánica | Sulfato de amonio, K₂SO₄, kieserita, yeso | Disponibilidad depende de mineralización y lixiviación. |

## Apéndice C. Reglas de seguridad del motor

Si falta variedad, edad, área o unidad, no calcular dosis.

Si el laboratorio no informa método para P/K, emitir diagnóstico provisional y solicitar método.

Si CE supera el umbral configurado, fraccionar o bloquear la recomendación automática.

Si pH es ácido y no existe Al/acidez de reserva, no recomendar cal.

Si el sensor es la única fuente, limitar la recomendación a baja confianza y solicitar laboratorio.

Guardar versión del motor, fuente bibliográfica y parámetros usados en cada análisis.

## Apéndice D. Formulación matemática ampliada y conversión de producción

Este apéndice convierte la producción que introduce el agricultor en una demanda anual de nutrientes y luego en cantidades de fertilizante. La unidad recomendada para el motor es kg de café oro/verde por hectárea. En Nicaragua, el café oro comercial corresponde al grano verde después del beneficiado seco; por eso, para el cálculo de extracción, “quintal oro” y “quintal verde” se tratan como la misma masa comercial. La interfaz debe distinguirlo de café uva, café pergamino y fanega uva.

### D.1 Unidades de producción y factores de conversión

El quintal comercial debe almacenarse con su masa explícita. La configuración inicial puede usar 1 qq oro = 46 kg, pero el valor debe poder cambiarse a 45.36 kg si la organización utiliza el quintal de 100 lb exactas. La normativa nicaragüense citada establece equivalencias comerciales para pergamino y fanega uva, mientras que Cenicafé documenta que los factores físicos dependen del estado de humedad y del beneficiado (República de Nicaragua, 1999; Uribe-Henao, 1977).

## Tabla 11. Conversión implementable en Agrifos

| Entrada del usuario | Conversión base | Fórmula del motor | Nivel de uso |
| --- | --- | --- | --- |
| Quintal oro | 1 qq oro = 46 kg oro/verde | kg_verde = qq_oro × 46 | Base recomendada |
| Quintal verde | 1 qq verde = 46 kg verde | qq_oro = qq_verde | Equivalente a oro |
| Café uva maduro | factor configurable; iniciar 5.0 kg uva/kg verde | kg_uva = kg_verde × F_uva_verde | Estimación agronómica |
| Quintal uva de 100 lb | 1 qq uva = 45.36 kg uva | qq_uva = kg_uva / 45.36 | Estimación de cosecha |
| Pergamino oreado/seco | equivalencia comercial nicaragüense | qq_oro = qq_pergamino × F_pergamino_oro | Usar solo con humedad definida |
| Fanega uva | 0.43 qq oro según equivalencia comercial | fanegas = qq_oro / 0.43 | No confundir con qq uva |

Nota. El valor F_uva_verde = 5.0 es un factor inicial configurable, no una constante universal. Debe reemplazarse por el rendimiento real del beneficio de cada finca. Un estudio de Cenicafé reportó 5.04 kg de cereza madura por kg de pergamino seco, por lo que no debe copiarse sin ajustar la diferencia entre pergamino seco y oro trillado.

$$
Y_{verde}\,[\mathrm{kg/ha}] = \frac{Q_{oro}\,m_{qq}}{A_{ha}}
$$

$$
Y_{uva}\,[\mathrm{kg/ha}] = Y_{verde}\,F_{uva/verde}
$$

$$
Q_{uva}\,[\mathrm{qq/ha}] = \frac{Y_{uva}}{m_{qq}}
$$

$$
A_{ha} = A_{manzanas}\times 0.7042
$$

### D.2 Coeficientes verificables de extracción

Para la extracción asociada a cosecha, se utilizan los coeficientes de Sadeghian, Mejía y Arcila: por cada 1,000 kg de café almendra con 11 % de humedad se extraen 30.9 kg de N, 2.3 kg de P, 36.9 kg de K, 4.3 kg de Ca, 2.3 kg de Mg y 1.2 kg de S. El motor convierte P y K a óxidos únicamente para compararlos con etiquetas comerciales.

## Tabla 12. Extracción estimada por quintal oro de 46 kg

| Nutriente | Coeficiente por 1,000 kg verde | Por 1 kg verde | Por 1 qq oro | Forma de etiqueta |
| --- | --- | --- | --- | --- |
| N | 30.9 kg N | 0.0309 kg | 1.421 kg N | N |
| P | 2.3 kg P | 0.0023 kg | 0.106 kg P | 0.243 kg P₂O₅ |
| K | 36.9 kg K | 0.0369 kg | 1.697 kg K | 2.045 kg K₂O |
| Ca | 4.3 kg Ca | 0.0043 kg | 0.198 kg Ca | 0.277 kg CaO |
| Mg | 2.3 kg Mg | 0.0023 kg | 0.106 kg Mg | 0.176 kg MgO |
| S | 1.2 kg S | 0.0012 kg | 0.055 kg S | S |

$$
P_2O_5=P\times2.291;\quad K_2O=K\times1.205;\quad CaO=Ca\times1.399;\quad MgO=Mg\times1.658
$$

### D.3 Demanda total antes de crédito del suelo

La extracción no representa por sí sola la dosis de fertilizante. El cultivo también debe mantener hojas, raíces, ramas y reservas. Para que el motor sea explícito, se define un factor de mantenimiento y crecimiento f_m. El valor se debe calibrar en Nicaragua; como configuración inicial se proponen tres escenarios, no una cifra única.

$$
D_i = \frac{Y_{verde}}{1000}\,E_i
$$

$$
D_{total,i}=D_i\left(1+f_{m,i}\right)
$$

| Escenario | f_m producción estable | Eficiencia η_N | Uso en Agrifos |
| --- | --- | --- | --- |
| Conservador / baja dosis | 0.10 | 0.60 | Suelo con buen reciclaje, lluvia controlada y buena eficiencia. |
| Central | 0.25 | 0.50 | Valor inicial para comparar escenarios; calibrar con parcelas. |
| Alto requerimiento / pérdidas | 0.35 | 0.40 | Pendiente, lluvia intensa, baja MO o alta carga; requiere fraccionamiento. |

Nota. f_m y η_N son parámetros del modelo, no coeficientes universales publicados para Nicaragua. Se muestran como escenarios para que el usuario vea la incertidumbre; el backend debe guardarlos y permitir su reemplazo por valores derivados de ensayos.

### D.4 Crédito de N del suelo y de fuentes orgánicas

El N total del laboratorio no equivale a N disponible. Si el laboratorio entrega N mineral, se utiliza directamente dentro de la profundidad muestreada. Si solo entrega N total y materia orgánica, puede estimarse un crédito provisional mediante mineralización, pero el resultado debe tener confianza baja o media y no debe ocultar el supuesto.

$$
M_{suelo}=10{,}000\,z_m\,\rho_b\,1000
$$

$$
N_{total}\,[\mathrm{kg/ha}]=\frac{\%N}{100}\,M_{suelo}
$$

$$
N_{mineralizado}\,[\mathrm{kg/ha}]=N_{total}\,f_{min}
$$

$$
N_{crédito}=N_{mineral}+N_{mineralizado}+N_{abono}-N_{inmovilizado}-N_{lixiviado\ estimado}
$$

Como parámetro de software, f_min debe ser una tabla local por textura, humedad, temperatura, cobertura y sistema de manejo. Si no existe una calibración, el motor puede mostrar un intervalo de sensibilidad de 1–3 % del N total anual, pero debe etiquetarlo como supuesto de simulación y no como medición. En producción, la salida preferida es un análisis de N mineral o una recomendación basada en historial y respuesta.

### D.5 Corrección por déficit

$$
Déficit_i=\max\!\left(0,D_{total,i}-C_{suelo,i}-C_{orgánico,i}-C_{reciclaje,i}\right)
$$

$$
Dosis_{fertilizante,i}=\frac{Déficit_i}{\eta_i}
$$

Para N, C_suelo,N se calcula con N mineral o mineralización estimada. Para P y K, C_suelo no se calcula como inventario bruto: se obtiene de una tabla de respuesta calibrada por método. Una implementación inicial puede mapear las categorías a créditos relativos configurables: bajo = 0.00, respuesta probable = 0.25, adecuado = 1.00 y alto = 1.10 de la demanda de cosecha; estos valores son parámetros de ingeniería que deben reemplazarse por curvas locales.

### D.6 Corrección por superávit

$$
Superávit_i=\max\!\left(0,C_{suelo,i}-D_{objetivo,i}\right)
$$

$$
F_{reducción,i}=\max\!\left(0,1-\gamma_i\frac{Superávit_i}{D_{objetivo,i}}\right)
$$

$$
Dosis_{corregida,i}=Dosis_{base,i}\,F_{reducción,i}
$$

La respuesta práctica a un superávit debe ser diferente según el nutriente. Si N mineral es alto, la dosis de N se reduce a cero o a una dosis de mantenimiento autorizada; si P es alto, se elimina P de la fórmula aunque se necesite N; si K es alto, se bloquea K y se evita KCl; si CE es alta, se penalizan todas las sales. Agrifos debe emitir una alerta de antagonismo cuando K alto coincida con Mg bajo o cuando pH ácido coincida con Al alto.

| Condición | Corrección inicial | Acción recomendada |
| --- | --- | --- |
| N bajo | Aplicar déficit / η_N | Fraccionar N en 2–4 aplicaciones y revisar lluvia. |
| N adecuado | Aplicar solo demanda de exportación y crecimiento | Evitar N tardío si hay maduración. |
| N alto o N mineral alto | Dosis N = 0 hasta nueva medición | No “compensar” con una fórmula NPK que contenga N. |
| P bajo | Aplicar P₂O₅ requerido con fuente independiente | DAP/MAP/TSP según N y costo. |
| P alto | Dosis P = 0 | Seleccionar urea, KCl o sulfatos sin P, según diagnóstico. |
| K bajo | Aplicar K₂O requerido / η_K | KCl o sulfato de potasio según CE/cloruro. |
| K alto | Dosis K = 0 | Revisar antagonismo con Mg y evitar fórmulas altas en K. |
| CE alta | Reducir carga salina y fraccionar | No subir dosis hasta confirmar con laboratorio. |

### D.7 Cantidades por producción de café oro/verde

La siguiente tabla muestra la extracción de nutrientes por hectárea para distintas producciones objetivo. No es una tabla de fertilizante comercial; es la base matemática que luego se ajusta por suelo, eficiencia y mantenimiento. Se utiliza 1 qq oro = 46 kg y los coeficientes publicados por Cenicafé.

## Tabla 13. Extracción por producción objetivo

| Producción | kg verde/ha | N kg/ha | P₂O₅ kg/ha | K₂O kg/ha | Ca kg/ha | Mg kg/ha | S kg/ha |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 qq/ha | 46 | 1.42 | 0.24 | 2.05 | 0.20 | 0.11 | 0.06 |
| 5 qq/ha | 230 | 7.11 | 1.21 | 10.23 | 0.99 | 0.53 | 0.28 |
| 10 qq/ha | 460 | 14.21 | 2.42 | 20.45 | 1.98 | 1.06 | 0.55 |
| 20 qq/ha | 920 | 28.43 | 4.85 | 40.91 | 3.96 | 2.12 | 1.10 |
| 50 qq/ha | 2300 | 71.07 | 12.12 | 102.27 | 9.89 | 5.29 | 2.76 |

Interpretación: 20 qq oro/ha equivalen a 920 kg verde/ha y exportan aproximadamente 28.43 kg N, 4.84 kg P₂O₅ y 40.90 kg K₂O, además de Ca, Mg y S. La recomendación comercial será mayor o menor según mantenimiento, créditos del suelo y eficiencia.

### D.8 Escenarios de N por producción

Para hacer visible el efecto de los supuestos, esta tabla calcula N bruto de fertilizante antes del crédito del suelo. La fórmula central es N_bruto = extracción_N × (1 + f_m) / η_N. El escenario central usa f_m = 0.25 y η_N = 0.50. No debe sumarse nuevamente la extracción después de aplicar esta cifra.

| Producción | N exportado | N bruto conservador | N bruto central | N bruto alto |
| --- | --- | --- | --- | --- |
| 1 qq/ha | 1.42 | 2.61 | 3.55 | 4.80 |
| 5 qq/ha | 7.11 | 13.03 | 17.77 | 23.99 |
| 10 qq/ha | 14.21 | 26.06 | 35.54 | 47.97 |
| 20 qq/ha | 28.43 | 52.12 | 71.07 | 95.94 |
| 50 qq/ha | 71.07 | 130.29 | 177.67 | 239.86 |

Estos escenarios muestran sensibilidad matemática. La app debe descontar créditos de suelo y abonos antes de convertir a urea u otra fuente. Para un suelo con N disponible alto, el motor puede devolver 0 kg/ha aun cuando la tabla bruta muestre una demanda potencial.

### D.9 Conversión de N a fertilizante

$$
kg_{urea/ha}=\frac{N_{dosis}\,[\mathrm{kg/ha}]}{0.46}
$$

$$
kg_{DAP/ha}=\frac{P_2O_{5,dosis}\,[\mathrm{kg/ha}]}{0.46}
$$

$$
N_{DAP}=kg_{DAP}\times0.18
$$

$$
kg_{urea\ complementaria}=\frac{\max(0,N_{dosis}-N_{DAP})}{0.46}
$$

$$
kg_{KCl/ha}=\frac{K_2O_{dosis}\,[\mathrm{kg/ha}]}{0.60}
$$

$$
kg_{K_2SO_4/ha}=\frac{K_2O_{dosis}\,[\mathrm{kg/ha}]}{0.50};\qquad S_{aportado}=kg_{K_2SO_4}\times0.17
$$

Ejemplo: si después de correcciones el motor determina 40 kg N/ha, la equivalencia simple es 86.96 kg urea/ha. Si además se requieren 20 kg P₂O₅/ha usando DAP, se usarían 43.48 kg DAP/ha, que aportan 7.83 kg N; la urea complementaria sería (40 − 7.83)/0.46 = 69.93 kg/ha. El optimizador puede elegir MAP, TSP, sulfato de amonio u otra fuente si cambian el costo, el pH o el S requerido.

### D.10 Ejemplo completo por quintal oro

Supóngase una parcela de 20 qq oro/ha, Caturra, 5,000 plantas/ha, etapa de expansión, suelo con P y K bajos, N disponible no medido y CE normal. La producción equivale a 920 kg verde/ha. La extracción es N 28.43 kg, P₂O₅ 4.84 kg y K₂O 40.90 kg por hectárea. Si se utiliza el escenario central, N bruto = 28.43 × 1.25 / 0.50 = 71.08 kg N/ha antes de crédito. Si el diagnóstico de laboratorio asigna un crédito N de 15 kg/ha, N déficit = 56.08 kg/ha. La dosis equivalente de urea sería 121.91 kg/ha, pero se divide en aplicaciones y se sustituye parcialmente si se requiere S, P o K.

$$
N_{déficit}=71.08-15.00=56.08\ \mathrm{kg\ N/ha}
$$

$$
urea=\frac{56.08}{0.46}=121.91\ \mathrm{kg/ha}
$$

$$
g_{urea/planta}=\frac{121.91\times1000}{5000}=24.38\ \mathrm{g/planta}
$$

Si el plan se fracciona en tres aplicaciones iguales, el valor operativo es 40.64 kg urea/ha por aplicación o 8.13 g/planta por aplicación. El motor debe mostrar que este resultado depende de f_m, η_N y el crédito de 15 kg/ha; si se modifica cualquiera de ellos, la recomendación cambia. Esta trazabilidad es más importante que presentar una cifra única como si fuera universal.

### D.11 Reglas para quintal uva maduro

Si el agricultor registra 100 qq uva madura y se conserva el factor inicial de 5.0 kg uva por kg verde, la producción equivalente es 20 qq oro/verde. Si el beneficio de la finca mide una relación distinta, se reemplaza F_uva_verde y se recalcula toda la demanda. La interfaz debe mostrar siempre el factor empleado y permitir introducir el rendimiento real obtenido en el beneficio.

$$
qq_{oro\ equivalentes}=\frac{qq_{uva}\,m_{qq}}{F_{uva/verde}\,m_{qq}}=\frac{qq_{uva}}{F_{uva/verde}}
$$

Con F = 5.0, 100 qq uva → 20 qq oro equivalentes. Con F = 5.5, 100 qq uva → 18.18 qq oro. Esta diferencia afecta directamente el cálculo de extracción y la dosis, por lo que no debe ocultarse ni fijarse permanentemente.

### D.12 Variables que deben quedar configurables

| Variable | Valor inicial | Rango/alternativa | Motivo |
| --- | --- | --- | --- |
| kg_qq_oro | 46 kg | 45.36–46 kg | Quintal comercial usado por la organización. |
| F_uva_verde | 5.0 kg/kg | medir por finca; 4.5–6.0 para sensibilidad | Madurez, variedad y beneficio cambian rendimiento. |
| f_m producción | 0.25 | 0.10–0.35 | Crecimiento y reservas adicionales a extracción. |
| η_N | 0.50 | 0.40–0.60 | Recuperación efectiva; calibrar por manejo y suelo. |
| η_P | 0.30 | 0.20–0.40 | P inmóvil y respuesta dependiente del extractante. |
| η_K | 0.55 | 0.40–0.70 | Pérdidas, textura y fraccionamiento. |
| máximo_N_por_aplicación | 40 kg N/ha | 20–60 kg N/ha | Límite operativo inicial; validar localmente. |
| factor_manzana | 0.7042 ha | configurable | Conversión de superficie en Nicaragua. |

La tabla anterior no convierte supuestos en “valores óptimos”. Son parámetros iniciales de software con intervalo de sensibilidad. La versión productiva debe sustituirlos por resultados de validación local y registrar la versión del conjunto de parámetros.
