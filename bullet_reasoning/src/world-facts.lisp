;;; Copyright (c) 2012, Lorenz Moesenlechner <moesenle@in.tum.de>
;;; All rights reserved.
;;; 
;;; Redistribution and use in source and binary forms, with or without
;;; modification, are permitted provided that the following conditions are met:
;;; 
;;;     * Redistributions of source code must retain the above copyright
;;;       notice, this list of conditions and the following disclaimer.
;;;     * Redistributions in binary form must reproduce the above copyright
;;;       notice, this list of conditions and the following disclaimer in the
;;;       documentation and/or other materials provided with the distribution.
;;;     * Neither the name of the Intelligent Autonomous Systems Group/
;;;       Technische Universitaet Muenchen nor the names of its contributors 
;;;       may be used to endorse or promote products derived from this software 
;;;       without specific prior written permission.
;;; 
;;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;;; ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
;;; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
;;; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
;;; SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;;; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
;;; CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
;;; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
;;; POSSIBILITY OF SUCH DAMAGE.

(in-package :btr)

(defmacro with-current-bullet-world (world &body body)
  `(let ((*current-bullet-world* ,world))
     ,@body))

(def-fact-group bullet-world-facts (assert retract)

  (<- (clear-bullet-world)
    (lisp-fun set *current-bullet-world* nil ?_))
  
  (<- (clear-bullet-world ?world)
    (not (bound ?world))
    (instance-of bt-reasoning-world ?world))
  
  (<- (bullet-world ?world)
    (not (bound ?world))
    (symbol-value *current-bullet-world* ?current-world)
    (-> (lisp-pred identity ?current-world)
        (== ?world ?current-world)
        (and
         (instance-of bt-reasoning-world ?world)
         (set-symbol-value *current-bullet-world* ?world))))

  (<- (bullet-world ?world)
    (lisp-type ?world bt-reasoning-world))

  (<- (copied-world ?world ?copy)
    (lisp-fun copy-world ?world ?copy))

  (<- (bullet-world ?world ?obj)
    ;; The world ?obj belongs to
    (get-slot-value ?obj world ?world))

  (<- (assert (object ?world ?object-type ?name ?pose . ?_))
    (object ?world ?name)
    (pose ?world ?p . ?pose)
    (assert (object-pose ?world ?name ?p)))
  
  (<- (assert (object ?world ?object-type ?name ?pose . ?args))
    (not (object ?world ?name))
    (lisp-fun apply add-object
              ?world ?object-type
              ?name ?pose ?args
              ?_))

  (<- (retract (object ?world ?name))
    (bullet-world ?world)
    (lisp-fun remove-object ?world ?name ?_))

  (<- (object ?world ?name)
    (bullet-world ?world)
    (%object ?world ?name ?_))

  (<- (object-type ?world ?name ?type)
    (bullet-world ?world)
    (%object ?world ?name ?obj)
    (lisp-type ?obj ?type))

  (<- (object-type ?world ?name ?type)
    (bullet-world ?world)
    (%object ?world ?name ?obj)
    (lisp-type ?obj household-object)
    (household-object-type ?world ?name ?type))

  (<- (household-object-type ?world ?name ?type)
    (bullet-world ?world)
    (object ?world ?name)
    (%object ?world ?name ?object-instance)
    (lisp-type ?object-instance household-object)
    (get-slot-value ?object-instance types ?types)
    (member ?type ?types))
  
  (<- (%object ?world ?name ?obj)
    (bound ?name)
    (lisp-type ?name symbol)
    (not (bound ?obj))
    (bullet-world ?world)
    (lisp-fun object ?world ?name ?obj)
    (lisp-type ?obj object))

  (<- (%object ?world ?name ?obj)
    (bound ?obj)
    (bullet-world ?world ?obj)
    (lisp-type ?obj object)
    (lisp-fun name ?obj ?name))

  (<- (%object ?world ?name ?obj)
    (not (bound ?name))
    (not (bound ?obj))
    (bullet-world ?world)
    (lisp-fun find-objects ?world ?objs)
    (member ?obj ?objs)
    (lisp-fun name ?obj ?name))
  
  ;; Performs one simulation step in the world
  (<- (step ?world)
    (step ?world 0.01))

  ;; Performs one simulation step of length ?dt in the world
  (<- (step ?world ?dt)
    (lisp-fun step-simulation ?world ?dt))

  ;; Simulates the next ?t seconds
  (<- (simulate ?world ?t)
    (lisp-fun simulate ?world ?t ?_))

  ;; Simulates the next ?t seconds with a step of ?dt
  (<- (simulate ?world ?t ?dt)
    (lisp-fun simulate ?world ?t ?dt ?_))

  (<- (simulate-realtime ?world ?t)
    (lisp-fun simulate ?world ?t 0.01 :realtime ?_)))

(def-fact-group force-dynamic-states ()

  (<- (contact ?world ?obj-1-name ?obj-2-name)
    (bound ?obj-1-name)
    (bound ?obj-2-name)
    (bullet-world ?world)
    (%object ?world ?obj-1-name ?obj-1)
    (%object ?world ?obj-2-name ?obj-2)    
    (lisp-fun perform-collision-detection ?world ?_)
    (lisp-pred contact-p ?world ?obj-1 ?obj-2))

  (<- (contact ?world ?obj-1-name ?obj-2-name)
    (bound ?obj-1-name)
    (not (bound ?obj-2-name))
    (bullet-world ?world)
    (%object ?world ?obj-1-name ?obj-1)
    (lisp-fun find-objects-in-contact ?world ?obj-1 ?objs)
    (member ?obj-2 ?objs)
    (%object ?world ?obj-2-name ?obj-2))

  (<- (contact ?world ?obj-1-name ?obj-2-name)
    (not (bound ?obj-1-name))
    (bound ?obj-2-name)
    (contact ?world ?obj-2-name ?obj-1-name))

  (<- (contact ?world ?obj-1-name ?obj-2-name)
    (not (bound ?obj-1-name))
    (not (bound ?obj-2-name))
    (bullet-world ?world)
    (lisp-fun find-all-contacts ?world ?contacts)
    (member (?obj-1 ?obj-2) ?contacts)
    (%object ?world ?obj-1-name ?obj-1)
    (%object ?world ?obj-2-name ?obj-2))

  (<- (contact ?world ?obj-1-name ?obj-2-name ?link)
    ;; Like CONTACT but also yields the name of a link that is in
    ;; contact with an object. This works only for multi-link objects
    ;; such as semantic maps or robots
    (contact ?world ?obj-1-name ?obj-2-name)
    (%object ?world ?obj-1-name ?obj-1)
    (%object ?world ?obj-2-name ?obj-2)
    (or (%link-contact ?obj-1 ?obj-2 ?link)
        (%link-contact ?obj-2 ?obj-1 ?link)))

  (<- (%link-contact ?robot-model ?obj ?link)
    (lisp-type ?robot-model robot-object)
    (lisp-fun link-contacts ?robot-model ?link-contacts)
    (member (?obj . ?link) ?link-contacts))

  (<- (stable ?world ?obj-name)
    (bullet-world ?world)
    (%object ?world ?obj-name ?obj)
    (%pose ?obj ?pose-1)
    (with-copied-world ?world
      (simulate ?world 5)
      ;; checking for active-tag does not always work and requires
      ;; pretty long simlation times. Additionally some bodies are
      ;; just very unstable and never get deactivated, e.g. cylinders.
      ;;
      ;; (lisp-pred stable-p ?obj)
      (%pose ?obj ?pose-2))
    (poses-equal ?pose-1 ?pose-2 (0.005 0.015)))

  (<- (stable ?world)
    (bullet-world ?world)
    (forall (object ?world ?_ ?o)
            (stable ?world ?o)))

  (<- (supported-by ?world ?top ?bottom)
    (bullet-world ?world)
    (contact ?world ?top ?bottom)
    (above ?world ?top ?bottom))

  (<- (supported-by ?world ?top ?bottom)
    (supported-by ?world ?top ?bottom ?_))
  
  (<- (supported-by ?world ?top ?bottom ?link)
    (bullet-world ?world)
    (contact ?world ?top ?bottom ?link)
    (above ?world ?top ?bottom ?link)))

(def-fact-group spatial-relations ()

  (<- (above ?w ?obj-1-name ?obj-2-name)
    (bullet-world ?w)
    (object ?w ?obj-1-name)
    (object ?w ?obj-2-name)
    (%object ?w ?obj-1-name ?obj-1)
    (%object ?w ?obj-2-name ?obj-2)
    (lisp-pred above-p ?obj-1 ?obj-2))

  (<- (above ?w ?obj-1-name ?obj-2-name ?link-name)
    (bullet-world ?w)
    (object ?w ?obj-1-name)
    (object ?w ?obj-2-name)
    (%object ?w ?obj-1-name ?obj-1)
    (%object ?w ?obj-2-name ?obj-2)
    (lisp-type ?obj-2 robot-object)
    (link ?w ?obj-2-name ?link-name)
    (lisp-pred above-link-p ?obj-1 ?obj-2 ?link-name))

  (<- (below ?w ?obj-1-name ?obj-2-name)
    (above ?w ?obj-2-name ?obj-1-name)))

(def-fact-group debug ()
  (<- (debug-window ?world)
    (bullet-world ?world)
    (lisp-fun add-debug-window ?world ?_))

  (<- (debug-costmap ?costmap)
    (lisp-fun add-costmap-function-object ?costmap ?_))

  (<- (debug-costmap ?costmap ?z)
    (lisp-fun add-costmap-function-object ?costmap ?z ?_)))
