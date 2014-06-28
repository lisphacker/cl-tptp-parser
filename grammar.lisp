;;;; -*- Mode: LISP, Syntax: COMMON-LISP, Package: MONTY.PARSER -*-
;;;;
;;;; Author: Gautham Ganapathy (gautham@lisphacker.org)
;;;;
;;;; TPTP language grammar specification.

(in-package :cl-tptp-parser.parser)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun dump-tree (x)
    (if (null x)
        "<>"
        (if (listp x)
            (let ((s ""))
              (loop for e in x do
                   (setf s (concatenate 'string s " " (dump-tree e))))
              (concatenate 'string "(" s ") "))
            (format nil "<~a ~a>" (token-terminal x) (token-text x)))))
  
  (defmacro dump-1 (name)
    (lambda (a)
      (format t "~s: ~s~%~%" name a)
      ;;(dump-tree a)
      a))
  
  (defmacro dump-2 (name)
    (lambda (a b)
      (format t "~s: (~s ~s)~%~%" name a b)
      ;;(dump-tree a)
      ;;(dump-tree b)
      (list a b)))
  
  (defmacro dump-3 (name)
    (lambda (a b c)
      (format t "~s: (~s ~s ~s)~%~%" name a b c)
      ;;(dump-tree a)
      ;;(dump-tree b)
      ;;(dump-tree c)
      (list a b c)))
  
  (defmacro dump-4 (name)
    (lambda (a b c d)
      (format t "~s: (~s ~s ~s ~s)~%~%" name a b c d)
      ;;(dump-tree a)
      ;;(dump-tree b)
      ;;(dump-tree c)
      (list a b c d)))
  )

(yacc:define-parser *tptp-grammar*
  (:start-symbol tptp-file)
  (:terminals (LOWER-WORD UPPER-WORD NUMBER STRING

                  ;; Formula types
                  THF TFF FOF CNF TPI

                  ;; Formula roles
                  AXIOM HYPOTHESIS LEMMA CONJECTURE

                  ;; System
                  INCLUDE

                  ;; Boolean
                  $TRUE $FALSE $DISTINCT

                  ;;Punctuation
                  |(| |)| |,| |.| |[| |]| |:|

                  ;; Operators
                  |!| |?| |~| |&| |\||
                  |<=>| |<=| |=>|
                  |<~>| |~\|| |~&|
                  |*| |+|
                  |-->|
                  
                  ;; Predicates
                  |=| |!=|))

  ;;(:precedence ((:left **) (:left %) (:left * / //) (:left + -)
    ;;            (:left << >> & \| ^ ~) (:left < > <= >= == !=) (:left NOT) (:left OR AND)))

  (:print-lookaheads t)

  (tptp-file
   (tptp-input           (lambda (a) (cons a nil)))
   (tptp-input tptp-file (lambda (a b) (cons a b))))

  (tptp-input
   annotated-formula
   include-stmt)

  (annotated-formula
   thf-annotated
   tff-annotated
   fof-annotated
   cnf-annotated
   tpi-annotated)
  
  (fof-annotated
   (FOF |(| name |,| formula-role |,| fof-formula #|annotations|# |)| |.| (lambda (a b c d e f g h i)
                                                                            (declare (ignore b d f h i))
                                                                            (make-instance 'fof-statement
                                                                                           :name (token-text c)
                                                                                           :role (token-text e)
                                                                                           :formula g
                                                                                           :token a)) ))

  (formula-role
   AXIOM
   HYPOTHESIS
   LEMMA
   CONJECTURE)

  ;; FOF formulae.
  (fof-formula
   (fof-logic-formula (dump-1 "fof-formula -> fof-logic-formula"))
   (fof-sequent (dump-1 "fof-formula -> fof-sequent")))
  
  (fof-logic-formula
   (fof-binary-formula (dump-1 "fof-logic-formula -> fof-binary-formula"))
   (fof-unitary-formula (dump-1 "fof-logic-formula -> fof-unitary-formula")))
  
  (fof-binary-formula
   fof-binary-nonassoc
   fof-binary-assoc)
  
  (fof-binary-nonassoc
   (fof-unitary-formula binary-connective fof-unitary-formula))

  (fof-binary-assoc
   fof-or-formula
   fof-and-formula)

  (fof-or-formula
   (fof-unitary-formula |\|| fof-unitary-formula)
   (fof-or-formula |\|| fof-unitary-formula))

  (fof-and-formula
   (fof-unitary-formula |&| fof-unitary-formula)
   (fof-and-formula |&| fof-unitary-formula))

  (fof-unitary-formula
   fof-quantified-formula
   fof-unary-formula
   (atomic-formula (dump-1 "fof-unitary-formula -> atomic-formula"))
   ( |(| fof-logic-formula |)| (lambda (a b c)
                                 (declare (ignore a c))
                                 b)))

  (fof-quantified-formula
   (fol-quantifier |[| fof-variable-list |]| |:| fof-unitary-formula))

  (fof-variable-list
   variable
   (variable |,| fof-variable-list))

  (fof-unary-formula
   (unary-connective fof-unitary-formula)
   fol-infix-unary)
   
  (fof-sequent
   (fof-tuple |-->| fof-tuple)
   ( |(| fof-sequent |)| ))

  (fof-tuple
   ( |[| |]| )
   ( |[| fof-tuple-list |]| ))

  (fof-tuple-list
   fof-logic-formula
   (fof-logic-formula |,| fof-tuple-list))


  ;; Special formulae.
  (fol-infix-unary
   (term infix-inequality term))

  ;; Connectives
  (fol-quantifier
   |!|
   |?|)

  (binary-connective
   |=>|
   |<=>|
   |<=|
   |<~>|
   |~\||
   |~&|)

  (assoc-connective
   |\||
   |&|)

  (unary-connective
   |~|)

  ;; First order atoms
  (atomic-formula
   (plain-atomic-formula (dump-1 "atomic-formula -> plain-atomic-formula"))
   defined-atomic-formula
   system-atomic-formula)

  (plain-atomic-formula
   ;;plain-term
   (proposition                 (lambda (a) (make-instance 'plain-atomic-formula
                                                           :predicate a)))
   (predicate |(| arguments |)| (lambda (a b c d)
                                  (declare (ignore b d))
                                  (make-instance 'plain-atomic-formula
                                                 :predicate a
                                                 :arguments c
                                                 :token a))))
                                           

  (proposition
   (predicate (dump-1 "proposition -> predicate")))
  
  (predicate
   (atomic-word (lambda (a) (make-instance 'predicate :name (token-text a) :token a))))

  
  (infix-inequality
   |!=|)

  ;; First order terms
  (term
   (function-term (dump-1 "term -> function-term"))
   (variable (dump-1 "term -> variable"))
   (conditional-term (dump-1 "term -> conditional-term"))
   (let-term (dump-1 "term -> let-term")))

  (function-term
   (plain-term (dump-1 "function-term -> plain-term"))
   (defined-term (dump-1 "function-term -> defined-term"))
   (system-term (dump-1 "function-term -> system-term")))

  (plain-term
   (constant (dump-1 "plain-term -> constant"))
   (functor |(| arguments |)| (dump-4 "plain-term -> functor ( arguments )")))

  #|(constant
  (functor (dump-1 "constant -> functor")))|#
  (constant
   (atomic-word (dump-1 "constant -> atomic-word")))

  #|(functor
   (atomic-word (lambda (a)
                  (make-instance 'functor
                                 :name (token-text a)
                                 :token a))))|#
  
  ;; System terms
  (variable
   UPPER-WORD)

  (arguments
   (term               (lambda (a) (cons a nil)))
   (term |,| arguments (lambda (a b c) (declare (ignore b)) (cons a c))))

  ;; Include directives
  (include-stmt
   (INCLUDE |(| filename |)| |.| (lambda (a b c d e)
                                   (declare (ignore b d e))
                                   (make-instance 'include :file (token-text c) :token a))))

  ;; General purpose
  (name
   (atomic-word (dump-1 "name -> atomic-word")))

  (atomic-word
   LOWER-WORD
   single-quoted)

  (filename
   single-quoted)
  
  (single-quoted
   STRING))
