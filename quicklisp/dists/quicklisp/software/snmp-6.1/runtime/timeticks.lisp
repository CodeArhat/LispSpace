;;;; -*- Mode: Lisp -*-
;;;; $Id: timeticks.lisp 838 2011-03-14 17:45:50Z binghe $

(in-package :asn.1)

(defclass timeticks (number-type)
  ()
  (:documentation "Timeticks: per second/100"))

(defun timeticks (time)
  (make-instance 'timeticks :value time))

(defmethod print-object ((object timeticks) stream)
  (let (hours minutes seconds seconds/100 (ticks (value-of object)))
    (multiple-value-bind (s s/100) (floor ticks 100)
      (setf seconds/100 s/100)
      (multiple-value-bind (h s) (floor s 3600) ; hours
        (setf hours h)
        (multiple-value-bind (m s) (floor s 60) ; minutes
          (setf minutes m
                seconds s))))
    (print-unreadable-object (object stream :type t)
      (format stream "(~D) ~D:~2,'0D:~2,'0D.~2,'0D"
              ticks hours minutes seconds seconds/100))))

(defmethod ber-encode ((tvalue timeticks))
  (let ((value (value-of tvalue)))
    (multiple-value-bind (v l) (ber-encode-integer value)
      (concatenate 'vector
                   (ber-encode-type 1 0 3)
                   (ber-encode-length l)
                   v))))

(defmethod ber-decode-value ((stream stream) (type (eql :timeticks)) length)
  (declare (type fixnum length) (ignore type))
  (timeticks (ber-decode-integer-value stream length)))

(eval-when (:load-toplevel :execute)
  (install-asn.1-type :timeticks 1 0 3))
