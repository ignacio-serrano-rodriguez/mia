; ---------------------------------------------------------------------
; Sistema Experto Recomendador de Mascotas
; ---------------------------------------------------------------------
; Parámetros a considerar para el cliente:
; - Espacio en la casa (grande, mediano, pequeno, apartamento)
; - Dinero disponible al mes (alto, medio, bajo)
; - Tiempo disponible para la mascota (mucho, moderado, poco)
; - Capacidad para sacarlo a la calle (alta, media, baja, nula)
; - Tiempo que pasa fuera de casa (mucho, moderado, poco)
; - Tipo de casa (casa-con-jardin, casa-sin-jardin, apartamento)
; - Necesita habitat específico (para la mascota)

; Hay que definir primero las plantillas (deftemplate) y luego las reglas (defrule).

; ---------------------------------------------------------------------
; Definiciones de Plantillas (deftemplate)
; ---------------------------------------------------------------------

(deftemplate usuario-preferencias
   (slot estado-recogida (type SYMBOL) (default esperando-datos-usuario)) ; Nuevo slot para controlar el flujo de preguntas
   (slot espacio-casa (type SYMBOL) (allowed-symbols grande mediano pequeno apartamento))
   (slot dinero-disponible (type SYMBOL) (allowed-symbols alto medio bajo))
   (slot tiempo-disponible-general (type SYMBOL) (allowed-symbols mucho moderado poco))
   (slot capacidad-paseo (type SYMBOL) (allowed-symbols alta media baja nula))
   (slot tiempo-fuera-casa (type SYMBOL) (allowed-symbols mucho moderado poco))
   (slot tipo-vivienda (type SYMBOL) (allowed-symbols casa-con-jardin casa-sin-jardin apartamento))
   (slot preferencias-recogidas (type SYMBOL) (default no)) ; Cambiado a 'no' por defecto
)

(deftemplate mascota
   (slot nombre (type STRING))
   (slot tamano (type SYMBOL) (allowed-symbols grande mediano pequeno))
   (slot necesidad-ejercicio (type SYMBOL) (allowed-symbols alta media baja)) ; Relacionado con capacidad-paseo y tiempo-disponible
   (slot coste-mensual (type SYMBOL) (allowed-symbols alto medio bajo)) ; Relacionado con dinero-disponible
   (slot necesidad-compania (type SYMBOL) (allowed-symbols alta media baja)) ; Relacionado con tiempo-fuera-casa
   (slot necesidad-espacio (type SYMBOL) (allowed-symbols grande mediano pequeno)) ; Relacionado con espacio-casa y tipo-vivienda
   (slot requiere-habitat-especifico (type SYMBOL) (allowed-symbols si no) (default no))
   (slot apta-para-apartamento (type SYMBOL) (allowed-symbols si no) (default si)) ; Si es adecuada para apartamentos
)

(deftemplate recomendacion
   (slot mascota-nombre (type STRING))
   (slot motivo (type STRING))
)

(deftemplate mascota-descartada
   (slot nombre (type STRING))
   (slot motivo (type STRING))
)

(deftemplate resultado-mostrado
   (slot valor (type SYMBOL) (allowed-symbols si no) (default no))
)

; ---------------------------------------------------------------------
; Hechos Iniciales (deffacts)
; ---------------------------------------------------------------------

(deffacts informacion-inicial
   ; Preferencias del Usuario se recogerán dinámicamente
   (usuario-preferencias) ; Hecho inicial para disparar la recogida de preferencias

   ; Lista de Mascotas (sin cambios)
   (mascota (nombre "Perro Grande (Labrador)") (tamano grande) (necesidad-ejercicio alta) (coste-mensual medio) (necesidad-compania alta) (necesidad-espacio grande) (apta-para-apartamento no))
   (mascota (nombre "Perro Mediano (Beagle)") (tamano mediano) (necesidad-ejercicio alta) (coste-mensual medio) (necesidad-compania media) (necesidad-espacio mediano) (apta-para-apartamento si))
   (mascota (nombre "Perro Pequeño (Chihuahua)") (tamano pequeno) (necesidad-ejercicio baja) (coste-mensual bajo) (necesidad-compania alta) (necesidad-espacio pequeno) (apta-para-apartamento si))
   (mascota (nombre "Gato") (tamano mediano) (necesidad-ejercicio baja) (coste-mensual medio) (necesidad-compania media) (necesidad-espacio mediano) (apta-para-apartamento si))
   (mascota (nombre "Pez") (tamano pequeno) (necesidad-ejercicio baja) (coste-mensual bajo) (necesidad-compania baja) (necesidad-espacio pequeno) (requiere-habitat-especifico si) (apta-para-apartamento si))
   (mascota (nombre "Hamster") (tamano pequeno) (necesidad-ejercicio baja) (coste-mensual bajo) (necesidad-compania baja) (necesidad-espacio pequeno) (requiere-habitat-especifico si) (apta-para-apartamento si))
   (mascota (nombre "Conejo") (tamano mediano) (necesidad-ejercicio media) (coste-mensual medio) (necesidad-compania media) (necesidad-espacio mediano) (requiere-habitat-especifico si) (apta-para-apartamento si))
   (mascota (nombre "Tortuga") (tamano pequeno) (necesidad-ejercicio baja) (coste-mensual bajo) (necesidad-compania baja) (necesidad-espacio mediano) (requiere-habitat-especifico si) (apta-para-apartamento si))
   (mascota (nombre "Pájaro Pequeño (Canario)") (tamano pequeno) (necesidad-ejercicio baja) (coste-mensual bajo) (necesidad-compania media) (necesidad-espacio pequeno) (requiere-habitat-especifico si) (apta-para-apartamento si))
)

; ---------------------------------------------------------------------
; Reglas (defrule)
; ---------------------------------------------------------------------

; Reglas para la recogida dinámica de preferencias del usuario

(defrule iniciar-recogida-de-preferencias
   (declare (salience 100))
   ?up <- (usuario-preferencias (estado-recogida esperando-datos-usuario) (preferencias-recogidas no))
   =>
   (printout t "--- Iniciando Recomendador de Mascotas ---" crlf)
   (printout t "Por favor, responda a las siguientes preguntas sobre sus preferencias." crlf crlf)
   (modify ?up (estado-recogida preguntando-espacio-casa))
)

(defrule solicitar-espacio-casa
   (declare (salience 90))
   ?up <- (usuario-preferencias (estado-recogida preguntando-espacio-casa))
   =>
   (printout t "PREGUNTA: ¿Espacio en su casa? (grande, mediano, pequeno, apartamento): " crlf)
   (bind ?respuesta (lowcase (read)))
   (if (lexemep ?respuesta) then (bind ?respuesta (sym-cat ?respuesta)))
   (if (member$ ?respuesta (create$ grande mediano pequeno apartamento)) then
      (modify ?up (espacio-casa ?respuesta) (estado-recogida preguntando-dinero-disponible))
   else
      (printout t "ERROR: Entrada no válida. Opciones: grande, mediano, pequeno, apartamento." crlf crlf)
      ; La regla se reactivará para volver a preguntar por espacio-casa
   )
)

(defrule solicitar-dinero-disponible
   (declare (salience 90))
   ?up <- (usuario-preferencias (estado-recogida preguntando-dinero-disponible))
   =>
   (printout t "PREGUNTA: ¿Dinero disponible al mes para la mascota? (alto, medio, bajo): " crlf)
   (bind ?respuesta (lowcase (read)))
   (if (lexemep ?respuesta) then (bind ?respuesta (sym-cat ?respuesta)))
   (if (member$ ?respuesta (create$ alto medio bajo)) then
      (modify ?up (dinero-disponible ?respuesta) (estado-recogida preguntando-tiempo-disponible-general))
   else
      (printout t "ERROR: Entrada no válida. Opciones: alto, medio, bajo." crlf crlf)
   )
)

(defrule solicitar-tiempo-disponible-general
   (declare (salience 90))
   ?up <- (usuario-preferencias (estado-recogida preguntando-tiempo-disponible-general))
   =>
   (printout t "PREGUNTA: ¿Tiempo general disponible para dedicarle? (mucho, moderado, poco): " crlf)
   (bind ?respuesta (lowcase (read)))
   (if (lexemep ?respuesta) then (bind ?respuesta (sym-cat ?respuesta)))
   (if (member$ ?respuesta (create$ mucho moderado poco)) then
      (modify ?up (tiempo-disponible-general ?respuesta) (estado-recogida preguntando-capacidad-paseo))
   else
      (printout t "ERROR: Entrada no válida. Opciones: mucho, moderado, poco." crlf crlf)
   )
)

(defrule solicitar-capacidad-paseo
   (declare (salience 90))
   ?up <- (usuario-preferencias (estado-recogida preguntando-capacidad-paseo))
   =>
   (printout t "PREGUNTA: ¿Capacidad para sacarlo a pasear? (alta, media, baja, nula): " crlf)
   (bind ?respuesta (lowcase (read)))
   (if (lexemep ?respuesta) then (bind ?respuesta (sym-cat ?respuesta)))
   (if (member$ ?respuesta (create$ alta media baja nula)) then
      (modify ?up (capacidad-paseo ?respuesta) (estado-recogida preguntando-tiempo-fuera-casa))
   else
      (printout t "ERROR: Entrada no válida. Opciones: alta, media, baja, nula." crlf crlf)
   )
)

(defrule solicitar-tiempo-fuera-casa
   (declare (salience 90))
   ?up <- (usuario-preferencias (estado-recogida preguntando-tiempo-fuera-casa))
   =>
   (printout t "PREGUNTA: ¿Cuánto tiempo pasa fuera de casa (mascota estaría sola)? (mucho, moderado, poco): " crlf)
   (bind ?respuesta (lowcase (read)))
   (if (lexemep ?respuesta) then (bind ?respuesta (sym-cat ?respuesta)))
   (if (member$ ?respuesta (create$ mucho moderado poco)) then
      (modify ?up (tiempo-fuera-casa ?respuesta) (estado-recogida preguntando-tipo-vivienda))
   else
      (printout t "ERROR: Entrada no válida. Opciones: mucho, moderado, poco." crlf crlf)
   )
)

(defrule solicitar-tipo-vivienda
   (declare (salience 90))
   ?up <- (usuario-preferencias (estado-recogida preguntando-tipo-vivienda))
   =>
   (printout t "PREGUNTA: ¿Tipo de vivienda? (casa-con-jardin, casa-sin-jardin, apartamento): " crlf)
   (bind ?respuesta (lowcase (read)))
   (if (lexemep ?respuesta) then (bind ?respuesta (sym-cat ?respuesta)))
   (if (member$ ?respuesta (create$ casa-con-jardin casa-sin-jardin apartamento)) then
      (printout t crlf "INFO: Preferencias del usuario recogidas." crlf)
      (modify ?up (tipo-vivienda ?respuesta) (estado-recogida recogida-completa) (preferencias-recogidas si))
   else
      (printout t "ERROR: Entrada no válida. Opciones: casa-con-jardin, casa-sin-jardin, apartamento." crlf crlf)
   )
)

; La regla 'iniciar-recomendador' original se elimina o su funcionalidad se integra en 'iniciar-recogida-de-preferencias'.

(defrule evaluar-mascota
   (declare (salience 50))
   (usuario-preferencias ; Condición actualizada para esperar la recogida completa
      (preferencias-recogidas si) ; Asegura que todas las preferencias han sido recogidas
      (espacio-casa ?uesp)
      (dinero-disponible ?udin)
      (tiempo-disponible-general ?utiempogen)
      (capacidad-paseo ?ucap)
      (tiempo-fuera-casa ?utfc)
      (tipo-vivienda ?uviv)
   )
   (mascota
      (nombre ?mnom)
      (tamano ?mtam)
      (necesidad-ejercicio ?mne)
      (coste-mensual ?mcoste)
      (necesidad-compania ?mnc)
      (necesidad-espacio ?mesp)
      (apta-para-apartamento ?mapa)
      (requiere-habitat-especifico ?mhab)
   )
   (not (recomendacion (mascota-nombre ?mnom)))
   (not (mascota-descartada (nombre ?mnom)))
   =>
   (bind ?compatible TRUE)
   (bind ?motivo-incompatibilidad "")

   ; 1. Espacio y tipo de vivienda
   (if (and (eq ?mapa no) (eq ?uviv apartamento)) then
      (bind ?compatible FALSE)
      (bind ?motivo-incompatibilidad (str-cat ?motivo-incompatibilidad "No apta para apartamento. "))
   )
   (if ?compatible then ; Solo seguir evaluando si aún es compatible
      ; Bloque para Espacio y tipo de vivienda (reemplazando cond)
      (if (and (eq ?mesp grande)
               (or (eq ?uesp pequeno)
                   (and (eq ?uesp apartamento) (neq ?uviv casa-con-jardin))))
      then
         (bind ?compatible FALSE)
         (bind ?motivo-incompatibilidad (str-cat ?motivo-incompatibilidad "Requiere mucho espacio. "))
      )
      (if (and ?compatible ; Adicionalmente, si aún es compatible tras la condición anterior de este bloque
               (eq ?mesp mediano)
               (eq ?uesp pequeno))
      then
         (bind ?compatible FALSE)
         (bind ?motivo-incompatibilidad (str-cat ?motivo-incompatibilidad "Requiere espacio mediano. "))
      )
   )

   ; 2. Dinero disponible vs coste mensual
   (if ?compatible then
      ; Bloque para Dinero (reemplazando cond)
      (if (and (eq ?mcoste alto) (neq ?udin alto))
      then
         (bind ?compatible FALSE)
         (bind ?motivo-incompatibilidad (str-cat ?motivo-incompatibilidad "Coste mensual alto. "))
      )
      (if (and ?compatible ; Adicionalmente, si aún es compatible tras la condición anterior de este bloque
               (eq ?mcoste medio) (eq ?udin bajo))
      then
         (bind ?compatible FALSE)
         (bind ?motivo-incompatibilidad (str-cat ?motivo-incompatibilidad "Coste mensual medio. "))
      )
   )

   ; 3. Necesidad de ejercicio vs capacidad de paseo y tiempo disponible
   (if ?compatible then
      ; Bloque para Ejercicio (reemplazando cond)
      (if (and (eq ?mne alta)
               (or (neq ?ucap alta) (eq ?utiempogen poco)))
      then
         (bind ?compatible FALSE)
         (bind ?motivo-incompatibilidad (str-cat ?motivo-incompatibilidad "Requiere mucho ejercicio/paseo y tiempo. "))
      )
      (if (and ?compatible ; Adicionalmente, si aún es compatible tras la condición anterior de este bloque
               (eq ?mne media)
               (or (eq ?ucap baja) (eq ?ucap nula) (eq ?utiempogen poco)))
      then
         (bind ?compatible FALSE)
         (bind ?motivo-incompatibilidad (str-cat ?motivo-incompatibilidad "Requiere ejercicio/paseo moderado y tiempo. "))
      )
   )

   ; 4. Necesidad de compañía vs tiempo fuera de casa
   (if ?compatible then
      ; Bloque para Compañía (reemplazando cond)
      (if (and (eq ?mnc alta)
               (or (eq ?utfc mucho) (eq ?utiempogen poco)))
      then
         (bind ?compatible FALSE)
         (bind ?motivo-incompatibilidad (str-cat ?motivo-incompatibilidad "Necesita mucha compañía o tiempo dedicado. "))
      )
      (if (and ?compatible ; Adicionalmente, si aún es compatible tras la condición anterior de este bloque
               (eq ?mnc media)
               (eq ?utfc mucho))
      then
         (bind ?compatible FALSE)
         (bind ?motivo-incompatibilidad (str-cat ?motivo-incompatibilidad "Necesita compañía moderada y pasas mucho tiempo fuera. "))
      )
   )
   
   ; 5. Hábitat específico (asumimos que el usuario no tiene uno a menos que se especifique)
   ;    Para este ejemplo, si requiere hábitat específico y no es un pez/hamster/pájaro/conejo/tortuga (ya definidos con ello),
   ;    podríamos añadir una pregunta al usuario o asumirlo como no compatible si no se gestiona.
   ;    Por ahora, si la mascota lo requiere, se asume que el usuario está dispuesto si la mascota es recomendada.

   (if ?compatible then
      (assert (recomendacion (mascota-nombre ?mnom) (motivo "Cumple con los criterios principales.")))
   else
      (assert (mascota-descartada (nombre ?mnom) (motivo ?motivo-incompatibilidad)))
   )
)

(defrule mostrar-recomendaciones
   (declare (salience -10))
   (exists (usuario-preferencias (preferencias-recogidas si))) ; Asegura que las preferencias fueron procesadas
   ?f <- (resultado-mostrado (valor no)) ; Hecho para controlar que se muestre una sola vez
   =>
   (retract ?f)
   (bind ?hay-recomendaciones FALSE)
   (printout t crlf "--- Resultados de la Recomendación ---" crlf)
   (do-for-all-facts ((?r recomendacion)) TRUE
      (printout t "[RECOMENDADA] " ?r:mascota-nombre " - Motivo: " ?r:motivo crlf)
      (bind ?hay-recomendaciones TRUE)
   )
   (if (not ?hay-recomendaciones) then
      (printout t "No se encontraron mascotas ideales con los criterios actuales." crlf)
   )
   (printout t crlf "--- Mascotas Consideradas y Descartadas ---" crlf)
   (do-for-all-facts ((?d mascota-descartada)) TRUE
      (printout t "[DESCARTADA] " ?d:nombre " - Motivo: " ?d:motivo crlf)
   )
   (printout t "-----------------------------------------" crlf)
   (assert (resultado-mostrado (valor si)))
)

(defrule preparar-flag-resultado
    (declare (salience 1)) ; Se ejecuta después de evaluar-mascota y antes de mostrar-recomendaciones
    (not (resultado-mostrado))
    (exists (usuario-preferencias (preferencias-recogidas si))) ; Condición clave
    =>
    (assert (resultado-mostrado (valor no)))
)

; Para ejecutar:
; 1. Carga este archivo: (load "recomendador_mascota.clp")
; 2. Reinicia el motor: (reset)
; 3. Ejecuta las reglas: (run)
;
; Puedes cambiar los valores en (deffacts informacion-inicial) para (usuario-preferencias)
; y volver a ejecutar (reset) y (run) para ver diferentes recomendaciones.
