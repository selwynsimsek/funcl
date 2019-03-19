(in-package :funcl)

(annot:enable-annot-syntax)

@export
(defvar *determinant* 
  (make-instance 'funcl-function 
                 :domain 'square-matrix 
                 :range 'scalar
                 :lambda-function (lambda (matrix) (magicl:det matrix))
                 :differentiator ()))

@export
(defvar *trace*
  (make-instance 'funcl-function
                 :domain 'square-matrix 
                 :range 'scalar 
                 :lambda-function (lambda (matrix)
                                    (reduce #'+ (loop for i from 0 below (magicl:matrix-cols matrix) 
                                                   collecting (magicl:ref matrix i i))))))

@export
(defvar *inverse* 
  (make-instance 'funcl-function 
                 :domain 'square-matrix 
                 :range 'square-matrix
                 :lambda-function (lambda (matrix) (magicl:inv matrix))))

@export
(defvar *identity*
  (make-instance 'funcl-function 
                 :domain 'square-matrix
                 :range 'square-matrix 
                 :lambda-function #'identity))

@export
(defgeneric transpose (matrix))

(defmethod transpose ((matrix magicl:matrix)) (magicl:transpose matrix))
(defmethod transpose ((matrix funcl-function))
  (make-instance 'funcl-function 
                 :domain (domain matrix)
                 :range (range matrix)
                 :lambda-function (lambda (arg) (transpose (evaluate matrix arg)))
                 :differentiator (lambda () (transpose (differentiate matrix)))))
(defmethod transpose ((matrix number)) matrix)
@export
(defgeneric complex-conjugate (arg))
(defmethod complex-conjugate ((arg number)) (conjugate arg))
(defmethod complex-conjugate ((arg simple-array)) (map 'vector 'complex-conjugate arg))
(defmethod complex-conjugate ((arg magicl:matrix)) (magicl:conjugate-entrywise arg))
@export
(defgeneric dot-product (a b))

(defmethod dot-product ((a number) (b number)) (* a b))
(defmethod dot-product ((a simple-array) (b simple-array)) (reduce #'+ (map 'vector #'* a 
                                                                            (complex-conjugate b))))
(defmethod dot-product ((a magicl:matrix) (b simple-array)) (dot-product (magicl::matrix-data a) b))
(defmethod dot-product ((a simple-array) (b magicl:matrix)) (dot-product a (magicl::matrix-data b)))
(defmethod dot-product ((a magicl:matrix) (b magicl:matrix)) (dot-product (magicl::matrix-data a)
                                                                          (magicl::matrix-data b)))
(defmethod dot-product ((c funcl-function) (d funcl-function))
  (make-instance 'combination-function :combination-operation #'dot-product
                                       :function-1 c :function-2 d
                                       :domain (domain c)
                                       :range 'scalar
                                       :differentiator (lambda () (+ (dot-product (differentiate c) d)
                                                                     (dot-product c (differentiate d))))
                                       :lambda-function (lambda (arg) (dot-product (evaluate c arg)
                                                                                   (evaluate d arg)))))

(defmethod dot-product ((c funcl-function) (d magicl:matrix)) (dot-product c (constant d)))
(defmethod dot-product ((c magicl:matrix) (d funcl-function)) (dot-product (constant c) d))
(defmethod dot-product ((c funcl-function) (d simple-array)) (dot-product c (constant d)))
(defmethod dot-product ((c simple-array) (d funcl-function)) (dot-product (constant c) d))


(defgeneric real-part (arg))
(defmethod real-part ((arg number)) (realpart arg))
(defmethod real-part ((arg magicl:matrix))
  (* 1/2 (+ arg (magicl:conjugate-entrywise arg))))
(defmethod real-part ((arg funcl-function))
  (make-instance 'funcl-function
                 :differentiator (lambda () (real-part (differentiate arg)))
                 :lambda-function (lambda (time) (real-part (evaluate arg time)))
                 :range (range arg)
                 :domain (domain arg)))

@export
(defun flatten-scalar (scalar)
  (cond
    ((numberp scalar) (realpart scalar))
    ((arrayp scalar) (realpart (aref scalar 0)))
    ((typep scalar 'magicl:matrix) (realpart (aref (magicl::matrix-data scalar) 0)))))

@export
(defgeneric matrix-trace (arg))

(defmethod matrix-trace ((arg number)) arg)
(defmethod matrix-trace ((arg magicl:matrix))
  (reduce #'+ (magicl:matrix-diagonal arg)))

(defmethod matrix-trace ((arg simple-array))
  (matrix-trace (simple-array->magicl-matrix arg)))

@export
(defun matrix-trace-function ()
  (make-instance 'funcl-function
                 :lambda-function (lambda (arg) (matrix-trace arg))
                 :domain 'square-matrix
                 :range 'scalar
                 :differentiator (lambda () (error "not implemented yet"))))

(defmethod matrix-trace ((arg funcl-function))
  (compose (matrix-trace-function) arg))
