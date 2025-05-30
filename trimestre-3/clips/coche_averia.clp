; --- Plantillas ---
(deftemplate estado-coche
    (slot fase-diagnostico (type SYMBOL) (default evaluacion-inicial))
    (slot tension-bateria (type FLOAT) (default 0.0))
    (slot tension-valida (type SYMBOL) (default no)) ; si, no
    (slot nivel-combustible (type SYMBOL) (allowed-symbols bajo medio alto desconocido) (default desconocido))
    (slot sonido-arranque (type SYMBOL) (allowed-symbols clic nada gira-lento gira-normal desconocido) (default desconocido))
)

(deftemplate diagnostico-info
    (slot tipo (type SYMBOL))
    (slot detalle (type STRING) (default ""))
)

; --- Hechos Iniciales ---
(deffacts hechos-iniciales
    (Coche_No_Arranca)
    (estado-coche) ; Se crea un estado inicial del coche
)

; --- Reglas de Diagnóstico ---

; Fase 1: Evaluación Eléctrica
(defrule iniciar-diagnostico-electrico
    (Coche_No_Arranca)
    ?ec <- (estado-coche (fase-diagnostico evaluacion-inicial))
    =>
    (printout t "INFO: Coche no arranca. Iniciando diagnóstico." crlf)
    (modify ?ec (fase-diagnostico pidiendo-tension))
)

(defrule solicitar-tension-bateria
    ?ec <- (estado-coche (fase-diagnostico pidiendo-tension) (tension-valida no))
    =>
    (printout t "PREGUNTA: ¿Cuál es la tensión de la batería (ej: 12.6)?: " crlf)
    (bind ?entrada (read))
    (if (numberp ?entrada) then
        (modify ?ec (tension-bateria (float ?entrada)) (tension-valida si) (fase-diagnostico evaluacion-electrica-completa))
    else
        (printout t "ERROR: Entrada no válida. Por favor, introduzca un número para la tensión." crlf)
        ; La regla se reactivará porque tension-valida sigue siendo 'no'
    )
)

(defrule bateria-baja-diagnosticada
    (estado-coche (fase-diagnostico evaluacion-electrica-completa) (tension-bateria ?t &:(< ?t 10.5)) (tension-valida si))
    (not (Diagnostico_Realizado))
    =>
    (printout t "DIAGNÓSTICO INTERMEDIO: Batería con tensión baja (" ?t "V)." crlf)
    (assert (diagnostico-info (tipo Bateria_Baja) (detalle (str-cat "Tensión: " ?t "V"))))
    (assert (Diagnostico_Realizado))
)

(defrule tension-ok-proceder-a-combustible
    ?ec <- (estado-coche (fase-diagnostico evaluacion-electrica-completa) (tension-bateria ?t &:(>= ?t 10.5)) (tension-valida si))
    (not (Diagnostico_Realizado))
    =>
    (printout t "INFO: Tensión de batería (" ?t "V) parece suficiente." crlf)
    (modify ?ec (fase-diagnostico investigando-combustible))
)

; Fase 2: Evaluación de Combustible
(defrule preguntar-nivel-combustible
    ?ec <- (estado-coche (fase-diagnostico investigando-combustible) (nivel-combustible desconocido))
    (not (Diagnostico_Realizado))
    =>
    (printout t "PREGUNTA: ¿Cuál es el nivel de combustible (introduzca 'bajo', 'medio', 'alto')?: " crlf)
    (bind ?respuesta (lowcase (read)))
    (if (or (eq ?respuesta bajo) (eq ?respuesta medio) (eq ?respuesta alto)) then
        (modify ?ec (nivel-combustible ?respuesta))
    else
        (printout t "ERROR: Respuesta no válida. Use 'bajo', 'medio', o 'alto'." crlf)
        ; La regla se reactivará porque nivel-combustible sigue 'desconocido'
    )
)

(defrule falta-combustible-diagnosticada
    (estado-coche (fase-diagnostico investigando-combustible) (nivel-combustible bajo))
    (not (Diagnostico_Realizado))
    =>
    (printout t "DIAGNÓSTICO INTERMEDIO: Nivel de combustible bajo." crlf)
    (assert (diagnostico-info (tipo Falta_Combustible) (detalle "El tanque de combustible está bajo.")))
    (assert (Diagnostico_Realizado))
)

(defrule combustible-ok-proceder-a-arranque
    ?ec <- (estado-coche (fase-diagnostico investigando-combustible) (nivel-combustible ?nc &:(neq ?nc bajo) &:(neq ?nc desconocido)))
    (not (Diagnostico_Realizado))
    =>
    (printout t "INFO: Nivel de combustible (" ?nc ") parece suficiente." crlf)
    (modify ?ec (fase-diagnostico investigando-arranque))
)

; Fase 3: Evaluación del Sistema de Arranque
(defrule preguntar-sonido-arranque
    ?ec <- (estado-coche (fase-diagnostico investigando-arranque) (sonido-arranque desconocido))
    (not (Diagnostico_Realizado))
    =>
    (printout t "PREGUNTA: ¿Qué sonido hace el coche al intentar arrancar (introduzca 'clic', 'nada', 'gira-lento', 'gira-normal')?: " crlf)
    (bind ?respuesta (lowcase (read)))
    (if (or (eq ?respuesta clic) (eq ?respuesta nada) (eq ?respuesta gira-lento) (eq ?respuesta gira-normal)) then
        (modify ?ec (sonido-arranque ?respuesta))
    else
        (printout t "ERROR: Respuesta no válida. Use 'clic', 'nada', 'gira-lento', o 'gira-normal'." crlf)
        ; La regla se reactivará porque sonido-arranque sigue 'desconocido'
    )
)

(defrule problema-motor-arranque-clic
    (estado-coche (fase-diagnostico investigando-arranque) (sonido-arranque clic))
    (not (Diagnostico_Realizado))
    =>
    (printout t "DIAGNÓSTICO INTERMEDIO: Sonido 'clic' al arrancar." crlf)
    (assert (diagnostico-info (tipo Problema_Motor_Arranque_Relay_Conexion) (detalle "El motor de arranque hace 'clic'. Podría ser el solenoide, conexiones sueltas/corroídas o batería débil (aunque la tensión pareciera OK).")))
    (assert (Diagnostico_Realizado))
)

(defrule problema-motor-arranque-nada
    (estado-coche (fase-diagnostico investigando-arranque) (sonido-arranque nada))
    (not (Diagnostico_Realizado))
    =>
    (printout t "DIAGNÓSTICO INTERMEDIO: No hay sonido al arrancar." crlf)
    (assert (diagnostico-info (tipo Problema_Sistema_Arranque_Electrico) (detalle "No hay ningún sonido. Podría ser interruptor de ignición, fusible, cableado al motor de arranque o el propio motor de arranque.")))
    (assert (Diagnostico_Realizado))
)

(defrule motor-arranque-gira-lento
    (estado-coche (fase-diagnostico investigando-arranque) (sonido-arranque gira-lento))
    (not (Diagnostico_Realizado))
    =>
    (printout t "DIAGNÓSTICO INTERMEDIO: El motor de arranque gira lento." crlf)
    (assert (diagnostico-info (tipo Bateria_Debil_o_Problema_Arranque) (detalle "El motor gira lento. Indica batería débil (a pesar de la tensión medida), conexiones deficientes o problema mecánico en el motor de arranque.")))
    (assert (Diagnostico_Realizado))
)


(defrule arranque-normal-pero-no-enciende
    (estado-coche (fase-diagnostico investigando-arranque) (sonido-arranque gira-normal))
    (not (Diagnostico_Realizado))
    =>
    (printout t "INFO: El motor de arranque gira normalmente pero el coche no enciende." crlf)
    (printout t "INFO: El problema podría estar en el sistema de ignición (bujías, bobina), entrega de combustible (bomba, inyectores) u otras causas no cubiertas en detalle." crlf)
    (assert (diagnostico-info (tipo Problema_Ignicion_o_Combustible_Avanzado) (detalle "Motor gira normal pero no arranca. Revisar sistema de ignición o entrega de combustible.")))
    (assert (Diagnostico_Realizado))
)


; Reglas para mostrar el diagnóstico final y manejar casos no diagnosticados
(defrule mostrar-diagnostico-final
    (declare (salience -10))
    ?di <- (diagnostico-info (tipo ?t) (detalle ?d))
    (Diagnostico_Realizado)
    =>
    (printout t "----------------------------------------------------" crlf)
    (printout t "DIAGNÓSTICO FINAL DEL SISTEMA: " ?t crlf)
    (if (neq ?d "") then (printout t "DETALLE: " ?d crlf))
    (printout t "----------------------------------------------------" crlf)
    (retract ?di) ; Solo retractar la info del diagnóstico para evitar múltiples impresiones
                  ; No retractar (Diagnostico_Realizado) para evitar bucles.
)

(defrule no-se-pudo-diagnosticar-completamente
    (declare (salience -20))
    (Coche_No_Arranca)
    ?ec <- (estado-coche (fase-diagnostico ?fase)
                          (tension-bateria ?tension)
                          (tension-valida ?valida)
                          (nivel-combustible ?combustible)
                          (sonido-arranque ?sonido))
    (not (Diagnostico_Realizado))
    (test (or (eq ?fase evaluacion-electrica-completa)
              (eq ?fase investigando-combustible)
              (eq ?fase investigando-arranque)
          ))
    =>
    (printout t "----------------------------------------------------" crlf)
    (printout t "DIAGNÓSTICO FINAL DEL SISTEMA: No se pudo determinar la causa con la información actual o las reglas disponibles." crlf)
    (printout t "Estado actual del diagnóstico: Fase=" ?fase ", Tensión=" ?tension "V (Válida:" ?valida "), Combustible=" ?combustible ", Sonido Arranque=" ?sonido crlf)
    (printout t "----------------------------------------------------" crlf)
    (assert (Diagnostico_Realizado))
)