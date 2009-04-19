;;; -*- Mode: Lisp; Package: Common-Lisp -*-

;;; This file is NOT part of xyzzy.

;;; corman_search.l
;;; http://www.cormanlisp.com/CormanLisp/patches/1_5/sequences.lisp

(in-package :lisp)

#+xyzzy (shadow '(search) (find-package "editor"))
(export '(search))

;;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;;  SEARCH
;;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

;;; Here goes the same OOP-from-chewing-gum approach as used in MAP: since the
;;; core algorithm of search is the same for all sequences (it is naive
;;; search--cannot do KMP because we deal with a more general case) but the
;;; rules of efficient element retrieval and position advancing are different,
;;; we package up the sequence-type specific operations behind a bunch of
;;; closures and call closures to perform the operations without knowing their
;;; implementation.  Since some closures have to share the captured state, we
;;; manufacture them in groups returned as multiple values.

(defun make-getter-and-resetter (sequence length start end from-end)
  ;; Return two closures; the first enumerates the elements of the
  ;; sequence, starting either from START or from the END, depending
  ;; on FROM-END value.  The second "resets" the first to the original
  ;; position.  LENGTH is passed by the caller to avoid doing it twice
  ;; on lists.
  (if (listp sequence)
      (let* ((tail (if from-end
                       (nthcdr (- length end) (reverse sequence))
                       (nthcdr start sequence)))
             (s tail))
        (values #'(lambda () (pop s))
                #'(lambda () (setq s tail))))
      (let* ((base (if from-end end (1- start)))
             (i base)
             (step (if from-end -1 1)))
        (values #'(lambda () (aref sequence (setq i (+ i step))))
                #'(lambda () (setq i base))))))

(defun make-getter-and-advancer (sequence length start end from-end)
  ;; Return two closures; the first enumerates the elements of the
  ;; sequence, starting either from START or from the END, depending
  ;; on FROM-END value.  The second advances the original position by
  ;; one element and resets the first closure to the new original
  ;; position.  LENGTH is passed by the caller to avoid doing it twice
  ;; on lists.
  (if (listp sequence)
      (let* ((tail (if from-end
                       (nthcdr (- length end) (reverse sequence))
                       (nthcdr start sequence)))
             (s tail))
        (values #'(lambda () (pop s))
                #'(lambda () (pop tail) (setq s tail))))
      (let* ((base (if from-end end (1- start)))
             (i base)
             (step (if from-end -1 1)))
        (values #'(lambda () (aref sequence (setq i (+ i step))))
                #'(lambda () (setq i (setq base (+ base step))))))))

(defun search (sequence1 sequence2 
                    &key (from-end nil)
                         (test #'eql) 
                         test-not
                         key
                         (start1 0) (start2 0)
                         end1 end2)
  (if test-not (setq test #'(lambda (x y) (not (funcall test-not x y)))))
  (let (length1
        length2
        (predicate (if key
                       #'(lambda (a b) (funcall test
                                                (funcall key a)
                                                (funcall key b)))
                       test)))
    (multiple-value-setq (length1 length2 end1 end2)
      (validate-2-bounding-indices sequence1 sequence2 start1 end1 start2 end2))
    ;; Lightning crackles at the tips of my fingers...
    (multiple-value-bind (pattern-elt-getter pattern-resetter)
        (make-getter-and-resetter sequence1 length1 start1 end1 from-end)
      (multiple-value-bind (seq-elt-getter seq-advancer)
          (make-getter-and-advancer sequence2 length2 start2 end2 from-end)
        (let ((pat-length (- end1 start1)))
          (dotimes (si (- end2 start2 (1- pat-length)))
            (block try-match
              (dotimes (pat-i pat-length)
                (unless (funcall predicate
                                 (funcall pattern-elt-getter)
                                 (funcall seq-elt-getter))
                  (return-from try-match nil)))
              ;; pattern match loop complete, we've got a match
              (return-from search (if from-end
                                      (- end2 (- end1 start1) si)
                                      (+ start2 si))))
            ;; returned from try-match - no match at SI
            (funcall pattern-resetter)
            (funcall seq-advancer)))))))

(defun validate-2-bounding-indices (sequence1 sequence2
                                    start1 end1 start2 end2)
  ;; => (VALUES length1 length2 actual-end1 actual-end2)
  (let ((length1 (length sequence1))
        (length2 (length sequence2)))
    (unless end1 (setq end1 length1))
    (unless end2 (setq end2 length2))
    (unless (and (integerp start1) (integerp end1)
                 (integerp start2) (integerp end2)
                 (<= 0 start1 end1 length1)
                 (<= 0 start2 end2 length2))
      (error "Invalid arguments: START1 = ~S, END1 = ~S, START2 = ~S, END2 = ~S"
             start1 end1 start2 end2))
    (values length1 length2 end1 end2)))

;;; corman_search.l ends here
