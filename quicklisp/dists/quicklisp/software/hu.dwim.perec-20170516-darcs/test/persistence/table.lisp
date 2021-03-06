;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2006 by the authors.
;;;
;;; See LICENCE for details.

(in-package :hu.dwim.perec.test)

(def suite* (test/persistence/table :in test/persistence))

(def test test/persistence/table/persistent-object ()
  (is (not (primary-table-of (find-class 'persistent-object)))))

(def persistent-class* table-t1-test ()
  ((name :type string)))
   
(def persistent-class* table-t2-test (table-t1-test)
  ((name)))

(def test test/persistence/table/inheritance ()
  (is (not (null (find "_name" (columns-of (primary-table-of (find-class 'table-t1-test))) :key #'hu.dwim.rdbms::name-of :test #'string=))))
  (is (null (find "_name" (columns-of (primary-table-of (find-class 'table-t2-test))) :key #'hu.dwim.rdbms::name-of :test #'string=))))

(def test test/persistence/table/view (instances)
  (bind ((classes (delete-duplicates (mapcar #'class-of instances)))
         (class-count (length classes)))
    (iter (for i :from 0 :below (expt 2 class-count))
          (for selected-classes = (iter (for j :initially 1 :then (* 2 j))
                                        (for class :in classes)
                                        (unless (zerop (logand i j))
                                          (collect class))))
          (for query = (make-query-for-classes-and-slots selected-classes nil))
          (for records = (when query
                           (execute (format-sql-to-string query))))
          (for record-count = (length records))
          (is (= record-count
                 (count-if (lambda (instance)
                             (some [eq (class-of instance) !1] selected-classes))
                           instances))
              "The number of returned records ~A is not consistent with the number of instances matching to the selected classes ~A" record-count selected-classes)
          (iter (for record :in-sequence records)
                (for oid = (first-elt record))
                (is (find oid instances :key #'oid-of) "Returned an oid ~A which is not among the given instances" oid)))))

(def suite* (test/persistence/table/x :in test/persistence/table))

(def persistent-class* table-x1-test ()
  ((s1 #f :type boolean))
  (:abstract #t)
  (:direct-store :push-down))

(def persistent-class* table-x2-test (table-x1-test)
  ((s2 #t :type boolean)))

(def persistent-class* table-x3-test (table-x2-test)
  ((s3 #f :type boolean)))

(def persistent-class* table-x4-test (table-x1-test)
  ((s2 #f :type boolean))
  (:abstract #t)
  (:direct-store :push-down))

(def persistent-class* table-x5-test (table-x4-test)
  ((s3 #f :type boolean)))

(def persistent-class* table-x6-test (table-x1-test)
  ((s2 #f :type boolean))
  (:abstract #t))

(def persistent-class* table-x7-test (table-x6-test)
  ((s3 #f :type boolean)))

(def test test/persistence/table/x/1 ()
  (with-transaction
    (bind ((x1-class (find-class 'table-x1-test))
           (x1-table (primary-table-of x1-class))
           (x1-s1-slot (find-slot 'table-x1-test 's1)))
      (is (null (effective-store-of x1-class)))
      (is (null (primary-class-of x1-s1-slot)))
      (is (null x1-table)))))

(def test test/persistence/table/x/2 ()
  (with-transaction
    (bind ((x2-class (find-class 'table-x2-test))
           (x2-table (primary-table-of x2-class))
           (x2-s1-slot (find-slot 'table-x2-test 's1))
           (x2-s2-slot (find-slot 'table-x2-test 's2)))
      (is (equal (effective-store-of x2-class)
                 '((table-x2-test table-x2-test) (table-x1-test table-x2-test) (persistent-object table-x2-test))))
      (is (eq (primary-class-of x2-s1-slot) x2-class))
      (is (eq (primary-class-of x2-s2-slot) x2-class))
      (is (not (null x2-table)))
      (is (equal (mapcar 'hu.dwim.rdbms::name-of (columns-of x2-table))
                 '("_oid" "_s1" "_s2")))
      (finishes (make-instance 'table-x2-test)))))

(def test test/persistence/table/x/3 ()
  (with-transaction
    (bind ((x2-class (find-class 'table-x2-test))
           (x3-class (find-class 'table-x3-test))
           (x3-table (primary-table-of x3-class))
           (x3-s1-slot (find-slot 'table-x3-test 's1))
           (x3-s2-slot (find-slot 'table-x3-test 's2))
           (x3-s3-slot (find-slot 'table-x3-test 's3)))
      (is (equal (effective-store-of x3-class)
                 '((table-x3-test table-x3-test) (table-x2-test table-x2-test) (table-x1-test table-x2-test) (persistent-object table-x2-test))))
      (is (eq (primary-class-of x3-s1-slot) x2-class))
      (is (eq (primary-class-of x3-s2-slot) x2-class))
      (is (eq (primary-class-of x3-s3-slot) x3-class))
      (is (not (null x3-table)))
      (is (equal (mapcar 'hu.dwim.rdbms::name-of (columns-of x3-table))
                 '("_oid" "_s3")))
      (finishes (make-instance 'table-x3-test)))))

(def test test/persistence/table/x/4 ()
  (with-transaction
    (bind ((x4-class (find-class 'table-x4-test))
           (x4-table (primary-table-of x4-class))
           (x4-s1-slot (find-slot 'table-x4-test 's1))
           (x4-s2-slot (find-slot 'table-x4-test 's2)))
      (is (null (effective-store-of x4-class)))
      (is (null (primary-class-of x4-s1-slot)))
      (is (null (primary-class-of x4-s2-slot)))
      (is (null x4-table)))))

(def test test/persistence/table/x/5 ()
  (with-transaction
    (bind ((x5-class (find-class 'table-x5-test))
           (x5-table (primary-table-of x5-class))
           (x5-s1-slot (find-slot 'table-x5-test 's1))
           (x5-s2-slot (find-slot 'table-x5-test 's2))
           (x5-s3-slot (find-slot 'table-x5-test 's3)))
      (is (equal (effective-store-of x5-class)
                 '((table-x5-test table-x5-test) (table-x4-test table-x5-test) (table-x1-test table-x5-test) (persistent-object table-x5-test))))
      (is (eq (primary-class-of x5-s1-slot) x5-class))
      (is (eq (primary-class-of x5-s2-slot) x5-class))
      (is (eq (primary-class-of x5-s3-slot) x5-class))
      (is (not (null x5-table)))
      (is (equal (mapcar 'hu.dwim.rdbms::name-of (columns-of x5-table))
                 '("_oid" "_s1" "_s2" "_s3")))
      (finishes (make-instance 'table-x5-test)))))

(def test test/persistence/table/x/6 ()
  (with-transaction
    (bind ((x6-class (find-class 'table-x6-test))
           (x6-table (primary-table-of x6-class))
           (x6-s1-slot (find-slot 'table-x6-test 's1))
           (x6-s2-slot (find-slot 'table-x6-test 's2)))
      (is (equal (effective-store-of x6-class)
                 '((table-x6-test table-x6-test) (table-x1-test table-x6-test) (persistent-object table-x6-test))))
      (is (eq (primary-class-of x6-s1-slot) x6-class))
      (is (eq (primary-class-of x6-s2-slot) x6-class))
      (is (not (null x6-table)))
      (is (equal (mapcar 'hu.dwim.rdbms::name-of (columns-of x6-table))
                 '("_oid" "_s1" "_s2"))))))

(def test test/persistence/table/x/7 ()
  (with-transaction
    (bind ((x6-class (find-class 'table-x6-test))
           (x7-class (find-class 'table-x7-test))
           (x7-table (primary-table-of x7-class))
           (x7-s1-slot (find-slot 'table-x7-test 's1))
           (x7-s2-slot (find-slot 'table-x7-test 's2))
           (x7-s3-slot (find-slot 'table-x7-test 's3)))
      (is (equal (effective-store-of x7-class)
                 '((table-x7-test table-x7-test) (table-x6-test table-x6-test) (table-x1-test table-x6-test) (persistent-object table-x6-test))))
      (is (eq (primary-class-of x7-s1-slot) x6-class))
      (is (eq (primary-class-of x7-s2-slot) x6-class))
      (is (eq (primary-class-of x7-s3-slot) x7-class))
      (is (not (null x7-table)))
      (is (equal (mapcar 'hu.dwim.rdbms::name-of (columns-of x7-table))
                 '("_oid" "_s3")))
      (finishes (make-instance 'table-x7-test)))))

(def test test/persistence/table/x/view ()
  (with-transaction
    (purge-instances 'table-x1-test)
    (test/persistence/table/view (list (make-instance 'table-x2-test)
                                       (make-instance 'table-x3-test)
                                       (make-instance 'table-x5-test)
                                       (make-instance 'table-x7-test)))))

(def suite* (test/persistence/table/y :in test/persistence/table))

(def persistent-class* table-y1-test ()
  ((s1 #f :type boolean))
  (:abstract #t))

(def persistent-class* table-y2-test (table-y1-test)
  ())

(def persistent-class* table-y3-test (table-y1-test)
  ())

(def persistent-class* table-y4-test (table-y2-test table-y3-test)
  ((s2 #t :type boolean)))

(def test test/persistence/table/y/1 ()
  (with-transaction
    (bind ((y1-class (find-class 'table-y1-test))
           (y1-table (primary-table-of y1-class))
           (y1-s1-slot (find-slot 'table-y1-test 's1)))
      (is (equal (effective-store-of y1-class)
                 '((table-y1-test table-y1-test) (persistent-object table-y1-test))))
      (is (eq (primary-class-of y1-s1-slot) y1-class))
      (is (not (null y1-table)))
      (is (equal (mapcar 'hu.dwim.rdbms::name-of (columns-of y1-table))
                 '("_oid" "_s1"))))))

(def test test/persistence/table/y/2 ()
  (with-transaction
    (bind ((y1-class (find-class 'table-y1-test))
           (y2-class (find-class 'table-y2-test))
           (y2-table (primary-table-of y2-class))
           (y2-s1-slot (find-slot 'table-y2-test 's1)))
      (is (equal (effective-store-of y2-class)
                 '((table-y2-test table-y2-test) (table-y1-test table-y1-test) (persistent-object table-y1-test))))
      (is (eq (primary-class-of y2-s1-slot) y1-class))
      (is y2-table)
      (finishes (make-instance 'table-y2-test)))))

(def test test/persistence/table/y/3 ()
  (with-transaction
    (bind ((y1-class (find-class 'table-y1-test))
           (y3-class (find-class 'table-y3-test))
           (y3-table (primary-table-of y3-class))
           (y3-s1-slot (find-slot 'table-y3-test 's1)))
      (is (equal (effective-store-of y3-class)
                 '((table-y3-test table-y3-test) (table-y1-test table-y1-test) (persistent-object table-y1-test))))
      (is (eq (primary-class-of y3-s1-slot) y1-class))
      (is y3-table)
      (finishes (make-instance 'table-y3-test)))))

(def test test/persistence/table/y/4 ()
  (with-transaction
    (bind ((y1-class (find-class 'table-y1-test))
           (y4-class (find-class 'table-y4-test))
           (y4-table (primary-table-of y4-class))
           (y4-s1-slot (find-slot 'table-y4-test 's1))
           (y4-s2-slot (find-slot 'table-y4-test 's2)))
      (is (equal (effective-store-of y4-class)
                 '((table-y4-test table-y4-test) (table-y2-test table-y2-test) (table-y3-test table-y3-test) (table-y1-test table-y1-test) (persistent-object table-y1-test))))
      (is (eq (primary-class-of y4-s1-slot) y1-class))
      (is (eq (primary-class-of y4-s2-slot) y4-class))
      (is (not (null y4-table)))
      (is (equal (mapcar 'hu.dwim.rdbms::name-of (columns-of y4-table))
                 '("_oid" "_s2")))
      (finishes (make-instance 'table-y4-test)))))

(def test test/persistence/table/y/view ()
  (with-transaction
    (purge-instances 'table-y1-test)
    (test/persistence/table/view (list (make-instance 'table-y2-test)
                                       (make-instance 'table-y3-test)
                                       (make-instance 'table-y4-test)))))

(def suite* (test/persistence/table/z :in test/persistence/table))

(def persistent-class* table-z1-test ()
  ((s1 #f :type boolean))
  (:abstract #t)
  (:direct-store :push-down))

(def persistent-class* table-z2-test (table-z1-test)
  ((s2 #f :type boolean))
  (:direct-store (table-z1-test table-z1-test)))

(def persistent-class* table-z3-test (table-z1-test)
  ((s2 #f :type boolean))
  (:direct-store (table-z1-test table-z1-test)))

(def persistent-class* table-z4-test (table-z2-test table-z3-test)
  ((s3 #t :type boolean)))

(def persistent-class* table-z5-test (table-z1-test)
  ((s2 #t :type boolean)))

(def test test/persistence/table/z/1 ()
  (with-transaction
    (bind ((z1-class (find-class 'table-z1-test))
           (z1-table (primary-table-of z1-class))
           (z1-s1-slot (find-slot 'table-z1-test 's1)))
      (is (null (effective-store-of z1-class)))
      (is (null (primary-class-of z1-s1-slot)))
      (is (not (null z1-table)))
      (is (equal (mapcar 'hu.dwim.rdbms::name-of (columns-of z1-table))
                 '("_oid" "_s1"))))))

(def test test/persistence/table/z/2 ()
  (with-transaction
    (bind ((z1-class (find-class 'table-z1-test))
           (z2-class (find-class 'table-z2-test))
           (z2-table (primary-table-of z2-class))
           (z2-s1-slot (find-slot 'table-z2-test 's1))
           (z2-s2-slot (find-slot 'table-z2-test 's2)))
      (is (equal (effective-store-of z2-class)
                 '((table-z2-test table-z2-test) (table-z1-test table-z1-test) (persistent-object table-z2-test))))
      (is (eq (primary-class-of z2-s1-slot) z1-class))
      (is (eq (primary-class-of z2-s2-slot) z2-class))
      (is (not (null z2-table)))
      (is (equal (mapcar 'hu.dwim.rdbms::name-of (columns-of z2-table))
                 '("_oid" "_s2")))
      (finishes (make-instance 'table-z2-test)))))

(def test test/persistence/table/z/3 ()
  (with-transaction
    (bind ((z1-class (find-class 'table-z1-test))
           (z3-class (find-class 'table-z3-test))
           (z3-table (primary-table-of z3-class))
           (z3-s1-slot (find-slot 'table-z3-test 's1))
           (z3-s2-slot (find-slot 'table-z3-test 's2)))
      (is (equal (effective-store-of z3-class)
                 '((table-z3-test table-z3-test) (table-z1-test table-z1-test) (persistent-object table-z3-test))))
      (is (eq (primary-class-of z3-s1-slot) z1-class))
      (is (eq (primary-class-of z3-s2-slot) z3-class))
      (is (not (null z3-table)))
      (is (equal (mapcar 'hu.dwim.rdbms::name-of (columns-of z3-table))
                 '("_oid" "_s2")))
      (finishes (make-instance 'table-z3-test)))))

(def test test/persistence/table/z/4 ()
  (with-transaction
    (bind ((z1-class (find-class 'table-z1-test))
           (z3-class (find-class 'table-z3-test))
           (z4-class (find-class 'table-z4-test))
           (z4-table (primary-table-of z4-class))
           (z4-s1-slot (find-slot 'table-z4-test 's1))
           (z4-s2-slot (find-slot 'table-z4-test 's2))
           (z4-s3-slot (find-slot 'table-z4-test 's3)))
      (is (equal (effective-store-of z4-class)
                 '((table-z4-test table-z4-test) (table-z2-test table-z2-test) (table-z3-test table-z3-test) (table-z1-test table-z1-test) (persistent-object table-z3-test))))
      (is (eq (primary-class-of z4-s1-slot) z1-class))
      (is (eq (primary-class-of z4-s2-slot) z3-class))
      (is (eq (primary-class-of z4-s3-slot) z4-class))
      (is (not (null z4-table)))
      (is (equal (mapcar 'hu.dwim.rdbms::name-of (columns-of z4-table))
                 '("_oid" "_s3")))
      (finishes (make-instance 'table-z4-test)))))

(def test test/persistence/table/z/5 ()
  (with-transaction
    (bind ((z5-class (find-class 'table-z5-test))
           (z5-table (primary-table-of z5-class))
           (z5-s1-slot (find-slot 'table-z5-test 's1))
           (z5-s2-slot (find-slot 'table-z5-test 's1)))
      (is (equal (effective-store-of z5-class)
                 '((table-z5-test table-z5-test) (table-z1-test table-z5-test) (persistent-object table-z5-test))))
      (is (eq (primary-class-of z5-s1-slot) z5-class))
      (is (eq (primary-class-of z5-s2-slot) z5-class))
      (is (not (null z5-table)))
      (is (equal (mapcar 'hu.dwim.rdbms::name-of (columns-of z5-table))
                 '("_oid" "_s1" "_s2")))
      (finishes (make-instance 'table-z5-test)))))

(def test test/persistence/table/z/view ()
  (with-transaction
    (purge-instances 'table-z1-test)
    (test/persistence/table/view (list (make-instance 'table-z2-test)
                                       (make-instance 'table-z3-test)
                                       (make-instance 'table-z4-test)
                                       (make-instance 'table-z5-test)))))

(def suite* (test/persistence/table/v :in test/persistence/table))

(def persistent-class* table-v1-test ()
  ((s1 #f :type boolean))
  (:abstract #t)
  (:direct-store :push-down))

(def persistent-class* table-v2-test (table-v1-test)
  ((s2 #f :type boolean)))

(def persistent-class* table-v3-test (table-v1-test)
  ((s2 #f :type boolean)))

(def persistent-class* table-v4-test (table-v2-test table-v3-test)
  ((s3 #t :type boolean)))

(def test test/persistence/table/v/1 ()
  (with-transaction
    (bind ((v1-class (find-class 'table-v1-test))
           (v1-table (primary-table-of v1-class))
           (v1-s1-slot (find-slot 'table-v1-test 's1)))
      (is (null (effective-store-of v1-class)))
      (is (null (primary-class-of v1-s1-slot)))
      (is (null v1-table)))))

(def test test/persistence/table/v/2 ()
  (with-transaction
    (bind ((v2-class (find-class 'table-v2-test))
           (v2-table (primary-table-of v2-class))
           (v2-s1-slot (find-slot 'table-v2-test 's1))
           (v2-s2-slot (find-slot 'table-v2-test 's2)))
      (is (equal (effective-store-of v2-class)
                 '((table-v2-test table-v2-test) (table-v1-test table-v2-test) (persistent-object table-v2-test))))
      (is (eq (primary-class-of v2-s1-slot) v2-class))
      (is (eq (primary-class-of v2-s2-slot) v2-class))
      (is (not (null v2-table)))
      (is (set-equal (mapcar 'hu.dwim.rdbms::name-of (columns-of v2-table))
                     '("_oid" "_s1" "_s2")
                     :test #'equal))
      (finishes (make-instance 'table-v2-test)))))

(def test test/persistence/table/v/3 ()
  (with-transaction
    (bind ((v3-class (find-class 'table-v3-test))
           (v3-table (primary-table-of v3-class))
           (v3-s1-slot (find-slot 'table-v3-test 's1))
           (v3-s2-slot (find-slot 'table-v3-test 's2)))
      (is (equal (effective-store-of v3-class)
                 '((table-v3-test table-v3-test) (table-v1-test table-v3-test) (persistent-object table-v3-test))))
      (is (eq (primary-class-of v3-s1-slot) v3-class))
      (is (eq (primary-class-of v3-s2-slot) v3-class))
      (is (not (null v3-table)))
      (is (set-equal (mapcar 'hu.dwim.rdbms::name-of (columns-of v3-table))
                     '("_oid" "_s1" "_s2")
                     :test #'equal))
      (finishes (make-instance 'table-v3-test)))))

(def test test/persistence/table/v/4 ()
  (with-transaction
    (bind ((v3-class (find-class 'table-v3-test))
           (v4-class (find-class 'table-v4-test))
           (v4-table (primary-table-of v4-class))
           (v4-s1-slot (find-slot 'table-v4-test 's1))
           (v4-s2-slot (find-slot 'table-v4-test 's2))
           (v4-s3-slot (find-slot 'table-v4-test 's3)))
      (is (equal (effective-store-of v4-class)
                 '((table-v4-test table-v4-test) (table-v2-test table-v2-test) (table-v3-test table-v3-test) (table-v1-test table-v3-test) (persistent-object table-v3-test))))
      (is (eq (primary-class-of v4-s1-slot) v3-class))
      (is (eq (primary-class-of v4-s2-slot) v3-class))
      (is (eq (primary-class-of v4-s3-slot) v4-class))
      (is (not (null v4-table)))
      (is (equal (mapcar 'hu.dwim.rdbms::name-of (columns-of v4-table))
                 '("_oid" "_s3")))
      (finishes (make-instance 'table-v4-test)))))

(def test test/persistence/table/v/view ()
  (with-transaction
    (purge-instances 'table-v1-test)
    (test/persistence/table/view (list (make-instance 'table-v2-test)
                                       (make-instance 'table-v3-test)
                                       (make-instance 'table-v4-test)))))
