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

(defun constant-sequence (value)
  (lazy-list () (cont value)))

(defun random-number-sequence (lower-bound upper-bound)
  "Returns an infinite lazy list of random numbers between
`lower-bound' and `upper-bound'."
  (assert (>= upper-bound lower-bound))
  (if (= upper-bound lower-bound)
      (constant-sequence lower-bound)
      (lazy-list ()
        (cont (+ lower-bound (random (- upper-bound lower-bound)))))))

(defun points-in-sphere (radius)
  (lazy-mapcar
   (lambda (radius angle angle-2)
     (cl-transforms:make-3d-vector
      (* radius (sin angle))
      (* radius (cos angle))
      (* radius (sin angle-2))))
   (random-number-sequence 0 (float radius))
   (random-number-sequence 0 (* pi 2))
   (random-number-sequence 0 (* pi 2))))

(defun points-on-circle (radius)
  "Randomly generates points on a circle with `radius' that lies on
the x-y plane."
  (lazy-mapcar
   (lambda (radius angle)
     (cl-transforms:make-3d-vector
      (* radius (sin angle))
      (* radius (cos angle))
      0.0))
   (random-number-sequence 0 (float radius))
   (random-number-sequence 0 (* pi 2))))

(defun points-in-box (dimensions)
  "Randomly generates points in a box of the size `dimensions'"
  (let ((dimensions (ensure-vector dimensions)))
    (lazy-mapcar
     #'cl-transforms:make-3d-vector
     (random-number-sequence (/ (cl-transforms:x dimensions) -2)
                             (/ (cl-transforms:x dimensions) 2))
     (random-number-sequence (/ (cl-transforms:y dimensions) -2)
                             (/ (cl-transforms:y dimensions) 2))
     (random-number-sequence (/ (cl-transforms:z dimensions) -2)
                             (/ (cl-transforms:z dimensions) 2)))))

(defun points-along-line (start-point step &optional max-distance)
  "Generates a sequence of points along the line starting at
`start-point'"
  (let ((start-point (ensure-vector start-point))
        (step (ensure-vector step)))
    (assert (> (cl-transforms:v-norm step) 0))
    (if max-distance
        (let ((max-steps (truncate (/ max-distance (cl-transforms:v-norm step)))))
          (lazy-list ((curr start-point)
                      (n max-steps))
            (when (> n 0)
              (cont curr (cl-transforms:v+ curr step) (- n 1)))))
        (lazy-list ((curr start-point))
          (cont curr (cl-transforms:v+ curr step))))))

(defun points-on-line (start-point direction max-distance)
  "Randomly samples points on the line given by the vectors
`startp-point' and `direction'. Only points between (START-POINT -
MAX-DISTANCE * DIRECTION) and (START-POINT + MAX-DISTANCE * DIRECTION)
are generated"
  (let ((start-point (ensure-vector start-point))
        (direction (ensure-vector direction)))
    (let ((direction-normalized (cl-transforms:v*
                                 direction
                                 (/ (cl-transforms:v-norm direction)))))
      (lazy-mapcar (lambda (n)
                     (cl-transforms:v+
                      start-point
                      (cl-transforms:v* direction-normalized n)))
                   (random-number-sequence (- max-distance) max-distance)))))

(defun pose-on (bottom top)
  (let* ((aabb-bottom (aabb bottom))
         (aabb-top (aabb top))
         (ref (cl-transforms:v+
               (bounding-box-center aabb-bottom)
               (cl-transforms:make-3d-vector
                0 0 (/ (cl-transforms:z (bounding-box-dimensions aabb-bottom)) 2))
               (cl-transforms:make-3d-vector
                0 0 (/ (cl-transforms:z (bounding-box-dimensions aabb-top)) 2)))))
    (lazy-mapcar
     (compose (lambda (pt)
                (cl-transforms:make-pose
                 pt (cl-transforms:make-quaternion 0 0 0 1)))
              (curry #'cl-transforms:v+ ref))
     (cons
      ref
      (points-in-box
       (cl-transforms:make-3d-vector
        (cl-transforms:x (bounding-box-dimensions aabb-bottom))
        (cl-transforms:y (bounding-box-dimensions aabb-bottom))
        0))))))

(def-prolog-handler generate (bdgs ?values ?generator)
  "Lisp-calls the function call form `?generator' and binds every
single value to `value. If `?n' is specified, generates at most `?n'
solutions."
  (destructuring-bind (generator-fun &rest generator-args)
      (substitute-vars ?generator bdgs)
    (assert (fboundp generator-fun) ()
            "Generator function `~a' not valid" generator-fun)
    (list
     (unify (var-value ?values bdgs)
            (apply generator-fun generator-args)
            bdgs))))