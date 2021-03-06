;;;
;;; Copyright (c) 2010, Lorenz Moesenlechner <moesenle@in.tum.de>
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
;;;

(in-package :btr)

(setf *bullet-world-scaling-factor* 30.0d0)

(defclass bt-reasoning-world (bt-world)
  ((objects :initform (make-hash-table :test 'equal))))

(defgeneric invalidate-object (object)
  (:documentation "Invalidates an object. This method is called after
  restoring the world from a saved state and is responsible for
  re-initializing all objects with the new rigid bodies.")
  (:method ((obj t))
    nil))

(defgeneric objects (reasoning-world)
  (:documentation "Returns the list of objects in `reasoning-world'")
  (:method ((world bt-reasoning-world))
    (loop for obj being the hash-values of (slot-value world 'objects)
          collecting obj)))

(defgeneric object (world name)
  (:method ((world bt-reasoning-world) name)
    (gethash name (slot-value world 'objects))))

(defclass bt-reasoning-world-state (world-state)
  ((objects :reader objects :initarg :objects
            :documentation "alist of objects")))

(defmethod get-state ((world bt-reasoning-world))
  (let ((state (call-next-method)))
    (change-class state 'bt-reasoning-world-state
                  :objects (loop for name being the hash-keys of (slot-value world 'objects)
                                 using (hash-value object)
                                 collecting (cons name object)))))

(defmethod restore-state ((world-state bt-reasoning-world-state)
                          (world bt-reasoning-world))
  (prog1
      (call-next-method)
    (with-world-locked world
      (with-slots (objects) world
        (clrhash objects)
        (loop for (name . obj) in (objects world-state) do
          (let ((obj (if (eq world (world obj))
                         obj (copy-object obj world))))
            (setf (gethash name objects) obj)
            (invalidate-object obj)))))))

(defvar *current-bullet-world* (make-instance 'bt-reasoning-world))
