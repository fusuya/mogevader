(ql:quickload '(:trivial-gamekit :cl-bodge))

(defpackage moge
  (:use :cl :trivial-gamekit))

(in-package moge)

(defvar *white* (vec4 1 1 1 1))
(defvar *black* (vec4 0 0 0 1))
(defvar *red*   (vec4 1 0 0 1))
(defvar *green* (vec4 0 1 0 1))
(defvar *blue*  (vec4 0 0 1 1))
(defvar *yellow* (vec4 1 1 0 1))
(defvar *beam-color* (vec4 0 0.6 0.9 1))
(defparameter *window-w* 1024)
(defparameter *window-h* 768)
(defparameter *game-w* 800)
(defparameter *border-s* (vec2 *game-w* 0))
(defparameter *border-e* (vec2 *game-w* *window-h*))
(defvar *tower-border-s* (vec2 0 150))
(defvar *tower-border-e* (vec2 800 150))
(defparameter *canon* nil)
(defparameter *bullets* nil)
(defparameter *invaders* nil)
(defvar *invader-max* 50)
(defvar *invader-size* (gamekit:vec2 32 32)) ;;(w h)
(defvar *cursor* nil)
(defparameter *sample-size* (vec2 32 32))
(defparameter *canon-pos* (vec2 810 20))
(defparameter *missile-pos* (vec2 850 20))
(defparameter *beam-pos* (vec2 890 20))
(defparameter *factory-pos* (vec2 930 20))
(defparameter *wall-pos* (vec2 810 60))
(defvar *player* nil)
(defvar *font24* nil)
(defvar *font28* nil)
(defvar *font32* nil)
(defvar *font64* nil)
(defvar *font128* nil)
(defvar *font300* nil)
(defvar *hit-cd* 30)

(defvar *canon-explain* "HOGE")
(defvar *canon-max* 20)
(defvar *missile-max* 10)
(defvar *beam-max* 10)
(defvar *factory-max* 10)

(gamekit:register-resource-package :keyword "img/")
(gamekit:define-image :crab "crab.png")
(gamekit:define-image :crab32 "crab32.png")
(gamekit:define-image :canon "canon.png")
(gamekit:define-image :missile "missile.png")
(gamekit:define-image :invaders "invaders.png")
(gamekit:define-image :factory "factory.png")
(define-image :ms-explosion "ms-explosion.png")
(define-image :beam "beam.png")
(define-image :wall "wall.png")
(define-font :mplus "mplus-1mn-regular.ttf")


(defclass obj ()
  ((pos    :initarg :pos    :initform (gamekit:vec2 0 0) :accessor pos)
   (hp     :initarg :hp     :initform 3                  :accessor hp)
   (maxhp  :initarg :maxhp  :initform 3                  :accessor maxhp)
   (money  :initarg :money  :initform 0                  :accessor money)
   (lv     :initarg :lv     :initform 1                  :accessor lv)
   (hit-cd :initarg :hit-cd :initform 0                  :accessor hit-cd) ;;弾に当たる間隔
   (size   :initarg :size   :initform (vec2 0 0)         :accessor size)
   (size/2 :initarg :size/2 :initform (vec2 0 0)         :accessor size/2)))


(defclass player ()
  ((towers     :initarg :towers     :initform nil    :accessor towers)
   (tower-num  :initarg :tower-num  :initform '(:canon 0 :missile 0 :beam 0 :factory 0)
	       :accessor tower-num)
   (hp         :initarg :hp         :initform 10     :accessor hp)
   (wave       :initarg :wave       :initform 1      :accessor wave)
   (state      :initarg :state      :initform :title :accessor state)
   (score      :initarg :score      :initform 0      :accessor score)
   (money      :initarg :money      :initform 0      :accessor money)
   (money-c    :initarg :money-c    :initform 0      :accessor money-c)
   (money-t    :initarg :money-t    :initform 60     :accessor money-t)
   (explosions :initarg :explosions :initform nil    :accessor explosions)
   (bullets    :initarg :bullets    :initform nil    :accessor bullets)))


(defclass circle ()
  ())

(defclass rectan ()
  ())


(defclass wall (obj rectan)
  ((img-pos :initarg :img-pos :initform (vec2 0 0)   :accessor img-pos)))


(defclass tower (obj)
  ((interval :initarg :interval :initform 0 :accessor interval)
   (power    :initarg :power    :initform 1 :accessor power)
   (atk-c    :initarg :atk-c    :initform 0 :accessor atk-c)))

(defclass factory (tower rectan)
  ((inc-money :initarg :inc-money :initform 0.3 :accessor inc-money)
   (time-c :initarg :time-c :initform 0.3 :accessor time-c)))

(defclass canon (tower rectan)
  ())

(defclass beam (tower rectan)
  ((penetrate :initarg :penetrate :initform 2 :accessor penetrate)))

(defclass missile (tower rectan)
  ((r :initarg :r :initform 0 :accessor r)))


(defclass invader (tower rectan)
  ((state   :initarg :state   :initform :alive       :accessor state)
   (race    :initarg :race    :initform :alive       :accessor race)
   (shot    :initarg :shot    :initform nil          :accessor shot)
   (img-pos :initarg :img-pos :initform (vec2 0 0)   :accessor img-pos)))

(defclass invader-wave ()
  ((invader-list    :initarg :invader-list  :initform nil :accessor invader-list)
   (start-turn      :initarg :start-turn    :initform nil :accessor start-turn)
   (turn        :initarg :turn        :initform nil          :accessor turn)
   (current     :initarg :current     :initform 0            :accessor current)
   (move-frame  :initarg :move-frame  :initform 0            :accessor move-frame)
   (moved?      :initarg :moved?      :initform nil          :accessor moved?)
   (invader-max :initarg :invader-max :initform 0            :accessor invader-max)
   (spd         :initarg :spd         :initform (vec2 10 0)  :accessor spd)))

(defclass invaders ()
  ((invaders    :initarg :invaders    :initform nil          :accessor invaders) ;; invader-waveのlist
   (bullet-max  :initarg :bullet-max  :initform 1            :accessor bullet-max)
   (pre-time    :initarg :pre-time    :initform 0            :accessor pre-time)
   (frame       :initarg :frame       :initform 0            :accessor frame)
   (bullets     :initarg :bullets     :initform nil          :accessor bullets)
   (blt-c       :initarg :blt-c       :initform 0            :accessor blt-c)
   
   ))

(defclass bullet (tower)
  ((r     :initarg :r     :initform 0          :accessor r)
   (spd  :initarg  :spd   :initform (vec2 0 0) :accessor spd)
   (color :initarg :color :initform *white*    :accessor color)))
   

(defclass explosion (bullet circle)
  ((explosion-time :initarg :explosion-time :initform 20 :accessor explosion-time)))

(defclass invader-blt (bullet circle)
  ())

(defclass canon-blt (bullet circle)
  ())

(defclass missile-blt (bullet rectan)
  ())

(defclass beam-blt (beam bullet rectan)
  ())

(defclass cursor ()
  ((pos       :initarg :pos       :initform (gamekit:vec2 0 0) :accessor pos)
   (now       :initarg :now       :initform nil                :accessor now)
   (now-tower :initarg :now-tower :initform nil                :accessor now-tower)
   (selected  :initarg :selected  :initform nil                :accessor selected)
   (add?      :initarg :add?      :initform nil                :accessor add?)))


(gamekit:defgame mogevader () ()
  (:viewport-width *window-w*)
  (:viewport-height *window-h*)
  (:viewport-title ""))

(defparameter *test-wall* nil)
			       		       
(defun set-font ()
  (setf *font24* (make-font :mplus 24)
	*font28* (make-font :mplus 28)
	*font32* (make-font :mplus 32)
	*font64* (make-font :mplus 64)
	*font128* (make-font :mplus 128)
	*font300* (make-font :mplus 300)))

(defun init-data ()
  (setf *invaders* (make-instance 'invaders)
        *cursor* (make-instance 'cursor)
        *player* (make-instance 'player :hp 10 :money 100 :state :title)))
        


(defun random-create-invader (x y lv)
  (cond
    ((>= lv (random 40))
     (make-instance 'invader :pos (gamekit:vec2 (- (* x 32 1.2) 320)
						(+ 550 (* y 32 1.25)))
			     :size (vec2 32 32) :atk-c 150 :money 15
			     :img-pos (vec2 0 0) :hp (+ lv 3)
			     :maxhp (+ lv 3) :race :ika
			     :size/2 (vec2 16 16)))
    ((>= lv (random 30))
     (make-instance 'invader :pos (gamekit:vec2 (- (* x 32 1.2) 320)
						(+ 550 (* y 32 1.25)))
			     :size (vec2 32 32) :atk-c 200 :money 10
			     :img-pos (vec2 0 32) :hp (+ lv 2)
			     :maxhp (+ lv 2) :race :tako
			     :size/2 (vec2 16 16)))
    (t
     (make-instance 'invader :pos (gamekit:vec2 (- (* x 32 1.2) 320)
						(+ 550 (* y 32 1.25)))
			     :size (vec2 32 32) :atk-c 250 :money 5
			     :img-pos (vec2 0 64) :hp (+ lv 1)
			     :maxhp (+ lv 1) :race :crab
			     :size/2 (vec2 16 16)))))
     

;;敵作成
(defun create-invaders ()
  (with-slots (invaders) *invaders*
    ;;(incf (wave *player*))
    (let* ((lv (wave *player*))
	   (invader-num (min 100 (* (wave *player*) 10)))
	   (wave (make-instance 'invader-wave :spd (vec2 (+ 22 (* lv 2)) 0)
				:move-frame (floor *invader-max* invader-num))))
      ;;        (invader-x 10))
      ;;(setf invaders (make-array (* invader-y invader-x)))
      (loop :for n :from 0 :below invader-num ;;敵の数
            :do (multiple-value-bind (y x) (floor n 10) 
		  (push
		   (random-create-invader x y lv)
		   (invader-list wave))))
      (setf (invader-max wave) (length (invader-list wave))
	    (bullet-max *invaders*) (* lv 3))
      (push wave invaders))))


(defmethod hit? ((a circle) (b circle))
  (let* ((a-x (x (pos a))) (a-y (y (pos a)))
	 (b-x (x (pos b))) (b-y (y (pos b)))
	 (a-r (r a)) (b-r (r b)))
    (>= (+ a-r b-r) (sqrt (+ (expt (- b-x a-x) 2)
			     (expt (- b-y a-y) 2))))))

(defmethod hit? ((b rectan) (e rectan))
  (let* ((e-x1 (x (pos e))) 
         (e-x2 (+ e-x1 (x (size e))))
         (e-y1 (y (pos e)))
         (e-y2 (+ e-y1 (y (size e))))
         (b-x1 (x (pos b)))
         (b-x2 (+ b-x1 (x (size b))))
         (b-y1 (y (pos b)))
         (b-y2 (+ b-y1 (y (size b)))))
    (and (<= b-x1 e-x2)
         (<= e-x1 b-x2)
         (<= b-y1 e-y2)
         (<= e-y1 b-y2))))

;;
(defmethod hit? ((b circle) (e rectan))
  (with-slots (pos size) e
    (let* ((e-x1 (gamekit:x pos)) (e-x2 (+ e-x1 (x size)))
                                  (e-y1 (gamekit:y pos)) (e-y2 (+ e-y1 (y size)))
                                  (b-x (gamekit:x (pos b))) (b-y (gamekit:y (pos b)))
                                  (r (r b)))
      (or (and (>= e-x2 b-x e-x1)
               (>= (+ e-y2 r) b-y (- e-y1 r)))
          (and (>= (+ e-x2 r) b-x (- e-x1 r))
               (>= e-y2 b-y e-y1))
          (> (expt r 2) (+ (expt (- e-x1 b-x) 2)
                           (expt (- e-y1 b-y) 2)))
          (> (expt r 2) (+ (expt (- e-x2 b-x) 2)
                           (expt (- e-y2 b-y) 2)))
          (> (expt r 2) (+ (expt (- e-x2 b-x) 2)
                           (expt (- e-y1 b-y) 2)))
          (> (expt r 2) (+ (expt (- e-x1 b-x) 2)
                           (expt (- e-y2 b-y) 2)))))))


;;選択したタワーの周りに□表示
(defun draw-select-area (now &key (color *white*))
  (draw-rect (pos now) (x *sample-size*) (y *sample-size*) :stroke-paint color :thickness 2))


;;選択しているタワーを追加
(defun add-tower ()
  (with-slots (selected) *cursor*
    (push selected (towers *player*))
    (decf (money *player*) (money selected))
    (setf selected nil)))


;;サンプルからタワーを選択
(defun select-tower (tower)
  (with-slots (pos selected) *cursor*
    (let ((tower-pos (vec2 (- (x pos) 16) (y pos))))
      (setf selected tower
            (pos selected) tower-pos))))

;;カーソルが既存のタワーに重なっているか
(defun cursor-player-tower ()
  (loop :for tower :in (towers *player*)
	:do (with-slots (pos) tower
	      (when (and (>= (+ (x pos) (x *sample-size*)) (x (pos *cursor*)) (x pos))
			 (>= (+ (y pos) (y *sample-size*)) (y (pos *cursor*)) (y pos)))
		(setf (now-tower *cursor*) tower)
		(return-from cursor-player-tower))))
  (setf (now-tower *cursor*) nil))

;;選択してるタワーが既存のタワーに重なっていないか
(defun check-add-tower (selected)
  (loop :for tower :in (towers *player*)
	:do (with-slots (pos) tower
	      (when (hit? selected tower)
		(return-from check-add-tower t)))))

;;タワーを選んでいる状態
(defun cursor-tower-selected (x y)
  (with-slots (pos now selected add? now-tower) *cursor*
    (setf (x (pos selected)) (- x (x (size/2 selected)))
	  (y (pos selected)) (- y (y (size/2 selected)))
	  now nil
	  now-tower nil)
    (if (check-add-tower selected)
	(setf add? nil)
	(setf add? t))))

;;タワーを選んでいない状態
(defun cursor-tower-no-selected ()
  (with-slots (pos now selected add?) *cursor*
    (cursor-player-tower)
    (when (null (now-tower *cursor*))
      (cond ;;サンプルに重なっているか
	;;キャノン
	((and (>= (+ (x *canon-pos*) (x *sample-size*)) (x pos) (x *canon-pos*))
	      (>= (+ (y *canon-pos*) (y *sample-size*)) (y pos) (y *canon-pos*))
	      (>= (money *player*) 10))
	 (setf now (make-instance 'canon :interval 300 :pos *canon-pos* :money 10
					 :size (vec2 32 16) :size/2 (vec2 16 8))))
	;;ミサイル
	((and (>= (+ (x *missile-pos*) (x *sample-size*)) (x pos) (x *missile-pos*))
	      (>= (+ (y *missile-pos*) (y *sample-size*)) (y pos) (y *missile-pos*))
	      (>= (money *player*) 30))
	 (setf now (make-instance 'missile :interval 500 :pos *missile-pos* :money 30
					   :size (vec2 32 16) :size/2 (vec2 16 8)
					   :r 24)))
	;;ビーム
	((and (>= (+ (x *beam-pos*) (x *sample-size*)) (x pos) (x *beam-pos*))
	      (>= (+ (y *beam-pos*) (y *sample-size*)) (y pos) (y *beam-pos*))
	      (>= (money *player*) 20))
	 (setf now (make-instance 'beam :interval 400 :penetrate 2 :pos *beam-pos* :money 20
					:size (vec2 32 16) :size/2 (vec2 16 8))))
	;;wall
	((and (>= (+ (x *wall-pos*) (x *sample-size*)) (x pos) (x *wall-pos*))
	      (>= (+ (y *wall-pos*) (y *sample-size*)) (y pos) (y *wall-pos*))
	      (>= (money *player*) 10))
	 (setf now (make-instance 'wall :hp 3 :img-pos (vec2 0 0) :pos *wall-pos* :money 10
				  :size (vec2 32 16) :size/2 (vec2 16 8))))
	((and (>= (+ (x *factory-pos*) (x *sample-size*)) (x pos) (x *factory-pos*))
	      (>= (+ (y *factory-pos*) (y *sample-size*)) (y pos) (y *factory-pos*))
	      (>= (money *player*) 20))
	 (setf now (make-instance 'factory :hp 3 :pos *factory-pos* :money 20
				  :inc-money 0.3 :time-c (get-internal-real-time)
				  :size (vec2 32 16) :size/2 (vec2 16 8))))
	
	(t (setf now nil))))))

;;カーソルの状態カーソルがどこに重なっているか
(defun cursor-now (x y)
  (with-slots (pos now selected add?) *cursor*
    (setf (x pos) x
          (y pos) y)
    (if selected
	(cursor-tower-selected x y)
	(cursor-tower-no-selected))))

;;キャノンアップグレード
(defmethod  tower-upgrade ((tower canon))
  (incf (lv tower))
  (if (evenp (lv tower))
      (incf (power tower))
      (decf (interval tower) 10))
  (incf (money tower) 15))

;;ミサイルアップグレード
(defmethod  tower-upgrade ((tower missile))
  (incf (lv tower))
  (if (evenp (lv tower))
      (incf (power tower))
      (incf (r tower) 20))
  (incf (money tower) 20))

;;ビームアップグレード
(defmethod  tower-upgrade ((tower beam))
  (incf (lv tower))
  (if (evenp (lv tower))
      (incf (power tower))
      (incf (penetrate tower)))
  (incf (money tower) 20))

;;壁アップグレード
(defmethod  tower-upgrade ((tower wall))
  (incf (lv tower))
  (incf (maxhp tower) (floor (money tower) 10))
  (incf (hp tower) (floor (money tower) 10))
  (incf (money tower) 10)
  ;;(setf (hp tower) (maxhp tower))
  (cond
    ((>= (hp tower) 3)
     (setf (x (img-pos tower)) 0
	   (y (size tower)) 16
	   (y (size/2 tower)) 8))
    ((>= 2 (hp tower) 1)
     (setf (x (img-pos tower)) 32
	   (y (size tower)) 12
	   (y (size/2 tower)) 6))))

;;工場アップグレード
(defmethod  tower-upgrade ((tower factory))
  (incf (lv tower))
  (incf (inc-money tower) 0.1)
  (incf (money tower) 20))


(defun check-tower-border ()
  (with-slots (pos selected) *cursor*
    (and (>= (- (x *tower-border-e*) (x (size/2 selected))) (x pos) (+ (x *tower-border-s*) (x (size/2 selected))))
	 (>= (- (y *tower-border-e*) (y (size/2 selected))) (y pos) (y (size/2 selected))))))

;;nowの場に出てる数
(defun check-tower-num (now)
  (cond
    ((eq (type-of now) 'canon)
     (> *canon-max* (getf (tower-num *player*) :canon)))
    ((eq (type-of now) 'missile)
     (> *missile-max* (getf (tower-num *player*) :missile)))
    ((eq (type-of now) 'beam )
     (> *beam-max* (getf (tower-num *player*) :beam)))
    ((eq (type-of now) 'factory)
     (> *factory-max* (getf (tower-num *player*) :factory)))
    (t t)))

(defmethod gamekit:post-initialize ((app mogevader))
  (init-data)
  (set-font)
  (create-invaders)
  (gamekit:bind-button :escape :pressed
                       (lambda ()
                         (gamekit:stop)))
  (bind-button :mouse-right :pressed
	       (lambda ()
		 (case (state *player*)
		   (:title)
		   (:playing
		    (with-slots (selected now-tower) *cursor*
		      (cond
			(selected
			 (setf selected nil))
			((and now-tower
			      (>= (money *player*) (money now-tower)))
			 (decf (money *player*) (money now-tower))
			 (tower-upgrade now-tower)))))
		   (:gameover
		    (init-data)
		    (create-invaders)
		    (setf (state *player*) :playing)))))
  (gamekit:bind-button :mouse-left :pressed
                       (lambda ()
			 (case (state *player*)
			   (:title (setf (state *player*) :playing))
			   (:playing
			    (with-slots (selected now add?) *cursor*
			      (cond
				((and selected
				      add?
				      (check-tower-border))
				 (add-tower))
				((and now (null selected)
				      (check-tower-num now))
				 (select-tower now))))))))
  (gamekit:bind-cursor (lambda (x y)
                         (cursor-now x y))))
;;(gamekit:y pos) y)))))








(defun draw-sample ()
  (with-slots (add? selected pos now now-tower) *cursor*
    (draw-image *canon-pos* :canon)
    (draw-image *missile-pos* :missile)
    (draw-image *beam-pos* :beam)
    (draw-image *factory-pos* :factory)
    (draw-image *wall-pos* :wall :origin (vec2 0 0) :width 32 :height 16)
    (cond
      (now
       (draw-select-area now))
      (selected
       (if add?
	   (draw-select-area selected)
	   (draw-select-area selected :color *red*)))
      (now-tower
       (draw-select-area now-tower)))))
  

(defmethod draw-selected ((tower canon))
  (draw-image (pos tower) :canon))

(defmethod draw-selected ((tower missile))
  (draw-image (pos tower) :missile))

(defmethod draw-selected ((tower beam))
  (draw-image (pos tower) :beam))

(defmethod draw-selected ((tower wall))
  (draw-image (pos tower) :wall :origin (img-pos tower) :width 32 :height 16))

(defmethod draw-selected ((tower factory))
  (draw-image (pos tower) :factory))

(defun draw-cursor ()
  (with-slots (pos selected) *cursor*
    (when selected
      (draw-selected selected))))


(defun draw-player-status ()
  (draw-text (format nil "MONEY:~d" (money *player*)) (vec2 810 320) :fill-color *white* :font *font32*)
  (draw-text (format nil "HP:~d" (hp *player*)) (vec2 810 290) :fill-color *white* :font *font32*)
  (draw-text (format nil "WAVE:~d" (wave *player*)) (vec2 810 260) :fill-color *white* :font *font32*)
  (draw-text (format nil "SCORE:~d" (score *player*)) (vec2 810 230) :fill-color *white* :font *font32*))


(defun draw-explain-img (img-id w)
  (cl-bodge:draw-image (vec2 810 (- *window-h* (* (image-height img-id) 2)))
                       (* w 2)
                       (* (image-height img-id) 2)
                       (gamekit::resource-by-id img-id)
                       :scale-x 2 :scale-y 2))

;;キャノン説明
(defmethod tower-explain ((tower canon))
  (with-slots (power interval money lv size) tower
    (draw-explain-img :canon (x size))
    (macrolet ((hoge (a) `(decf ,a 30)))
      (let ((a 740))
	(draw-text (format nil "MONEY:~d" money) (vec2 810 (hoge a)) :fill-color *white* :font *font32*)
	(draw-text (format nil "Lv:~d" lv) (vec2 810 (hoge a)) :fill-color *white* :font *font32*)
	(draw-text (format nil "NAME:CANON") (vec2 810 (hoge a)) :fill-color *white* :font *font32*)
	(draw-text (format nil "POWER:~d" power) (vec2 810 (hoge a)) :fill-color *white* :font *font32*)
	(draw-text (format nil "ATK-SPEED:~d" interval) (vec2 810 (hoge a)) :fill-color *white* :font *font32*)))))

(defmethod tower-explain ((tower missile))
  (with-slots (power interval r money lv size) tower
    (draw-explain-img :missile (x size))
    (macrolet ((hoge (a) `(decf ,a 30)))
      (let ((a 740))
	(draw-text (format nil "MONEY:~d" money) (vec2 810 (hoge a)) :fill-color *white* :font *font32*)
	(draw-text (format nil "Lv:~d" lv) (vec2 810 (hoge a)) :fill-color *white* :font *font32*)
	(draw-text (format nil "NAME:MISSILE") (vec2 810 (hoge a)) :fill-color *white* :font *font32*)
	(draw-text (format nil "POWER:~d" power) (vec2 810 (hoge a)) :fill-color *white* :font *font32*)
	(draw-text (format nil "ATK-SPEED:~d" interval) (vec2 810 (hoge a)) :fill-color *white* :font *font32*)
	(draw-text (format nil "Explosion-Area:~d" r) (vec2 810 (hoge a)) :fill-color *white* :font *font32*)))))

;;beam説明
(defmethod tower-explain ((tower beam))
  (with-slots (power money lv interval penetrate size) tower
    (draw-explain-img :beam (x size))
    (macrolet ((hoge (a) `(decf ,a 30)))
      (let ((a 740))
	(draw-text (format nil "MONEY:~d" money) (vec2 810 (hoge a)) :fill-color *white* :font *font32*)
	(draw-text (format nil "Lv:~d" lv) (vec2 810 (hoge a)) :fill-color *white* :font *font32*)
	(draw-text (format nil "NAME:BEAM") (vec2 810 (hoge a)) :fill-color *white* :font *font32*)
	(draw-text (format nil "POWER:~d" power) (vec2 810 (hoge a)) :fill-color *white* :font *font32*)
	(draw-text (format nil "ATK-SPEED:~d" interval) (vec2 810 (hoge a)) :fill-color *white* :font *font32*)
	(draw-text (format nil "PENETRATE:~d" penetrate) (vec2 810 (hoge a)) :fill-color *white* :font *font32*)))))

;;wall説明
(defmethod tower-explain ((tower wall))
  (with-slots (hp money size lv) tower
    (draw-explain-img :wall (x size))
    (macrolet ((hoge (a) `(decf ,a 30)))
      (let ((a 740))
	(draw-text (format nil "MONEY:~d" money) (vec2 810 (hoge a)) :fill-color *white* :font *font32*)
	(draw-text (format nil "Lv:~d" lv) (vec2 810 (hoge a)) :fill-color *white* :font *font32*)
	(draw-text (format nil "NAME:WALL") (vec2 810 (hoge a)) :fill-color *white* :font *font32*)
	(draw-text (format nil "HP:~D" hp) (vec2 810 (hoge a)) :fill-color *white* :font *font32*)
	(draw-text "NO ATTACK" (vec2 810 (hoge a)) :fill-color *white* :font *font32*)
	(draw-text (format nil "GUARD ~d times" hp) (vec2 810 (hoge a)) :fill-color *white* :font *font32*)))))

;;factory説明
(defmethod tower-explain ((tower factory))
  (with-slots (hp money size lv inc-money) tower
    (draw-explain-img :factory (x size))
    (macrolet ((hoge (a) `(decf ,a 30)))
      (let ((a 740))
	(draw-text (format nil "MONEY:~d" money) (vec2 810 (hoge a)) :fill-color *white* :font *font32*)
	(draw-text (format nil "Lv:~d" lv) (vec2 810 (hoge a)) :fill-color *white* :font *font32*)
	(draw-text (format nil "NAME:FACTORY") (vec2 810 (hoge a)) :fill-color *white* :font *font32*)
	(draw-text "NO ATTACK" (vec2 810 (hoge a)) :fill-color *white* :font *font32*)
	(draw-text (format nil "+ ~d/s MONEY" inc-money) (vec2 810 (hoge a)) :fill-color *white* :font *font32*)))))


(defun middle-explain (str1 &key (str2 nil) (str3 nil) (color *white*) (font *font32*))
  (draw-text str1 (vec2 810 450) :fill-color color :font font)
  (when str2
    (draw-text str2 (vec2 810 410) :fill-color color :font font))
  (when str3
    (draw-text str2 (vec2 810 370) :fill-color color :font font)))


(defun draw-tower-num ()
  (draw-text (format nil "canon ~d/20" (getf (tower-num *player*) :canon))
	     (vec2 810 450) :fill-color *white* :font *font32*)
  (draw-text (format nil "missile ~d/10" (getf (tower-num *player*) :missile))
	     (vec2 810 420) :fill-color *white* :font *font32*)
  (draw-text (format nil "beam ~d/10" (getf (tower-num *player*) :beam))
	     (vec2 810 390) :fill-color *white* :font *font32*)
   (draw-text (format nil "factory ~d/10" (getf (tower-num *player*) :factory))
	     (vec2 810 360) :fill-color *white* :font *font32*))

;;カーソルが重なてるタワーの説明
(defun draw-tower-explain ()
  (with-slots (now selected now-tower) *cursor*
    (cond
      (selected
       (tower-explain selected)
       (middle-explain "Right-Click" :str2 "CANCEL"))
      (now
       (tower-explain now)
       (draw-tower-num))
      (now-tower
       (tower-explain now-tower)
       (middle-explain "Right-Click" :str2 "UPGRADE"))
      (t (draw-tower-num)))))
       

;;HPバー
(defun draw-hp-bar (e bar-y)
  (with-slots (pos size hp maxhp) e
    (let* ((green-pos (vec2 (x pos) (- (y pos) bar-y)))
	   (w (x size))
	   (green-hp (* (/ hp maxhp) w))
	   (red-hp (- w green-hp))
	   (red-pos (vec2 (+ (x pos) green-hp) (- (y pos) bar-y))))
      (draw-rect green-pos green-hp 8 :fill-paint *green*)
      (draw-rect red-pos red-hp 8 :fill-paint *red*))))

(defmethod draw-tower ((tower canon))
  (draw-image (pos tower) :canon))

(defmethod draw-tower ((tower missile))
  (draw-image (pos tower) :missile))

(defmethod draw-tower ((tower beam))
  (draw-image (pos tower) :beam))

(defmethod draw-tower ((tower wall))
  (draw-image (pos tower) :wall :origin (img-pos tower) :width (x (size tower))
	      :height (y (size tower))))

(defmethod draw-tower ((tower factory))
  (draw-image (pos tower) :factory))

(defun draw-towers ()
  (with-slots (towers) *player*
    (loop :for tower :in towers
          :do (draw-tower tower)
	  (draw-hp-bar tower 12))))

(defmethod draw-bullet ((b circle))
  (with-slots (pos r color) b
    (gamekit:draw-arc pos r 0 6 :fill-paint color)))



(defun draw-explosion (b)
  (with-slots (pos r) b
    (draw-text (format nil "r:~d" r) (vec2 500 600) :fill-color *white* :font *font32*)
    (cl-bodge:draw-image (vec2 (- (x pos) r) (- (y pos) r))  (* r 2) (* r 2)
			 (gamekit::resource-by-id :ms-explosion)
			 :scale-x (/ (* r 2) (image-width :ms-explosion) 1.0)
			 :scale-y (/ (* r 2) (image-height :ms-explosion) 1.0))))
    ;;(draw-image (vec2 (- (x pos) r) (- (y pos) r)) :ms-explosion)))

(defmethod draw-bullet ((b rectan))
  (with-slots (pos size color) b
    (draw-rect pos (x size) (y size) :fill-paint color)))


;;
(defun draw-bullets ()
  (mapc #'(lambda (b) (draw-bullet b)) (bullets *invaders*))
  (loop :for bullet :in (bullets *player*)
        :do (draw-bullet bullet)))


(defun draw-explosions ()
  (mapc #'(lambda (b) (draw-explosion b)) (explosions *player*)))



;;
(defun draw-invaders ()
  (loop :for e-l :in (invaders *invaders*)
        :do (with-slots (invader-list) e-l
	      (loop :for e :in invader-list
		  :do (with-slots (pos state img-pos) e
			(when (eq state :alive)
			  (gamekit:draw-image pos :invaders :origin img-pos :width 32 :height 32)
			  (draw-hp-bar e 8)))))))




;;色々境界線
(defun border-lines ()
  (draw-line *border-s* *border-e* (vec4 1 1 1 1) :thickness 2)
  (draw-line (vec2 800 210) (vec2 *window-w* 210) (vec4 1 1 1 1) :thickness 2)
  (draw-line (vec2 800 350) (vec2 *window-w* 350) (vec4 1 1 1 1) :thickness 2)
  (draw-line (vec2 800 480) (vec2 *window-w* 480) (vec4 1 1 1 1) :thickness 2)
  ;;タワー置ける境界線
  (draw-line (vec2 0 150) (vec2 800 150) (vec4 1 1 1 1) :thickness 2))


(defun playing-draw ()
  (gamekit:draw-rect (gamekit:vec2 0 0) (gamekit:viewport-width) (gamekit:viewport-height)
		     :fill-paint (gamekit:vec4 0 0 0 1)) ;;TODO
  (gamekit:scale-canvas (/ (gamekit:viewport-width) *window-w*)
			(/ (gamekit:viewport-height) *window-h*))
  (border-lines)
  (draw-sample)
  (draw-cursor)
  (draw-player-status)
  ;; (cl-bodge:draw-image (gamekit:vec2 400 400) 48 48 (gamekit::resource-by-id :crab)
  ;;                                                   :scale-x 3 :scale-y 3
  ;;                                                   :translate-x 0)
  ;;(draw-text (format nil "viewport-w:~d" (viewport-width)) (vec2 10 500) :fill-color (vec4 1 1 1 1))
  ;;(draw-text (format nil "viewport-h:~d" (viewport-height)) (vec2 10 450)  :fill-color (vec4 1 1 1 1))
  ;;(draw-text (format nil "canvas-w:~d" (canvas-width)) (vec2 10 400)  :fill-color (vec4 1 1 1 1))
  ;;(draw-text (format nil "canvas-h:~d" (canvas-height)) (vec2 10 350)  :fill-color (vec4 1 1 1 1))
  (draw-tower-explain)
  (draw-towers)
  (draw-bullets)
  (draw-invaders)
  (draw-explosions))

;;タイトル画面
(defun title-draw ()
  (gamekit:draw-rect (gamekit:vec2 0 0) (gamekit:viewport-width) (gamekit:viewport-height)
		     :fill-paint (gamekit:vec4 0 0 0 1)) ;;TODO
  (draw-text "MOGEVADER" (vec2 30 500) :fill-color *white* :font *font300*)
  (draw-text "MOGEVADER" (vec2 35 500) :fill-color *red* :font *font300*)
  (draw-text "CLICK START" (vec2 380 200) :fill-color *white* :font *font64*))

;;ゲームオーバー画面
(defun gameover-draw ()
  (gamekit:draw-rect (gamekit:vec2 0 0) (gamekit:viewport-width) (gamekit:viewport-height)
		     :fill-paint (gamekit:vec4 0 0 0 1)) ;;TODO
  (draw-text "GAME OVER" (vec2 25 500) :fill-color *white* :font *font300*)
  (draw-text "GAME OVER" (vec2 33 500) :fill-color *white* :font *font300*)
  (draw-text "GAME OVER" (vec2 30 500) :fill-color *red* :font *font300*)
  (draw-text (format nil "SCORE : ~d" (score *player*))
	     (vec2 245 300) :fill-color *red* :font *font128*)
  (draw-text (format nil "SCORE : ~d" (score *player*))
	     (vec2 250 300) :fill-color *yellow* :font *font128*)
  (draw-text "RIGHT CLICK : RESTART"
	     (vec2 250 200) :fill-color *green* :font *font64*)
  (draw-text "    ESC     : GAME END"
	     (vec2 250 150) :fill-color *blue* :font *font64*))
;;
(defmethod gamekit:draw ((app mogevader))
  (case (state *player*)
    (:title (title-draw))
    (:playing (playing-draw))
    (:gameover (gameover-draw))))
     

;;インベーダー弾
(defmethod add-bullet ((e invader))
  (with-slots (pos size/2) e
    (when (>= *game-w* (x pos) 0)
      (let* ((r 6)
	     (blt (make-instance 'invader-blt :pos (vec2 (+ (x pos) (x size/2)) (- (y pos) r))
					      :r r :spd (vec2 0 -2) :color *red*)))
	(push blt (bullets *invaders*))))))

;;キャノン弾
(defmethod add-bullet ((tower canon))
  (with-slots (bullets) *player*
    (with-slots (pos size/2 power) tower
      (let* ((r 6)
             (blt (make-instance 'canon-blt :pos (vec2 (+ (x pos) (x size/2)) (+ (y pos) r))
					    :r r :spd (vec2 0 2) :color *green*
					    :power power)))
        (push blt bullets)))))

;;ミサイル弾追加
(defmethod add-bullet ((tower missile))
  (with-slots (pos size/2 size r power) tower
    (let* ((blt-pos (vec2 (- (+ (x pos) (x size/2)) 4) (+ (y pos) (y size))))
           (blt (make-instance 'missile-blt :pos blt-pos :size (vec2 8 16) :size/2 (vec2 4 8)
					    :color *yellow* :spd (vec2 0 2) :r r
					    :power power)))
      (push blt (bullets *player*)))))


;;ビーム弾追加
(defmethod add-bullet ((tower beam))
  (with-slots (pos size/2 size r penetrate power) tower
    (let* ((blt-pos (vec2 (- (+ (x pos) (x size/2)) 2) (+ (y pos) (y size))))
           (blt (make-instance 'beam-blt :pos blt-pos :size (vec2 4 26) :size/2 (vec2 2 13)
					 :color *beam-color* :spd (vec2 0 2)
					 :penetrate penetrate :power power)))
      (push blt (bullets *player*)))))


;;弾を消す
(defmacro delete-obj (obj objs)
  `(setf ,objs
	 (remove ,obj ,objs :test #'equal)))


;;インベーダーの玉とタワー当たったら
(defmethod bullet-hit-action ((b invader-blt) (tower tower))
  (decf (hp tower))
  (when (= (hp tower) 0)
    (delete-obj tower (towers *player*)))
  (delete-obj b (bullets *invaders*)))

;;インベーダーの玉と壁当たったら
(defmethod bullet-hit-action ((b invader-blt) (tower wall))
  (decf (hp tower))
  (when (<= (hp tower) 2) 
    (decf (y (size tower)) 4) ;;高さ減らす
    (decf (y (size/2 tower)) 2)
    (incf (x (img-pos tower)) 32))
  (delete-obj b (bullets *invaders*))
  (when (= (hp tower) 0)
    (delete-obj tower (towers *player*))))
	    
;;インベーダー弾とキャノン弾
(defmethod bullet-hit-action ((b invader-blt) (c canon-blt))
  (delete-obj b (bullets *invaders*))
  (delete-obj c (bullets *player*)))

;;インベーダー弾とbeam弾
(defmethod bullet-hit-action ((b invader-blt) (c beam-blt))
  (delete-obj b (bullets *invaders*)))

;;インベーダー弾とmissile弾
(defmethod bullet-hit-action ((b invader-blt) (c missile-blt))
  (delete-obj b (bullets *invaders*))
  (let* ((e-power (max 1 (floor (power c) 2)))
	 (ex (make-instance 'explosion :pos (vec2 (+ (x (pos c)) (x (size/2 c)))
						  (+ (y (pos c)) (y (size c))))
				       :r (r c) :power e-power)))
    (push ex (explosions *player*))
    (delete-obj c (bullets *player*))))


;;インベーダーの弾
(defmethod update ((b invader-blt))
  (with-slots (pos spd r) b
    (incf (y pos) (y spd))
    (if (<= (+ (y pos) r) 0) ;;画面外だったら消す
	(progn (delete-obj b (bullets *invaders*))
	       (decf (hp *player*))
	       (when (<= (hp *player*) 0)
		 (setf (state *player*) :gameover)))
	(progn
	  (loop :for tower :in (towers *player*)
		:do (when (hit? b tower)
		      (bullet-hit-action b tower)))
	  (loop :for blt :in (bullets *player*)
		:do (when (hit? b blt)
		      (bullet-hit-action b blt)))))))
          

(defun bullet-hit-common-action (b e)
  (decf (hp e) (power b))
  (when (>= 0 (hp e)) 
    (setf (state e) :dead)
    (incf (money *player*) (money e))
    (case (race e)
      (:ika (Incf (score *player*) 30))
      (:tako (Incf (score *player*) 20))
      (:crab (Incf (score *player*) 10)))))
      


;;キャノン弾がインベーダに当たった時
(defmethod bullet-hit-action ((b canon-blt) (e invader))
  (with-slots (power) b
    (with-slots (state hp) e
      (when (and (eq state :alive)
		 (hit? b e))
	(delete-obj b (bullets *player*))
        (bullet-hit-common-action b e)))))

;;ミサイル弾がインベーダーに当たった時
(defmethod bullet-hit-action ((b missile-blt) (e invader))
  (with-slots (size size/2 power pos) b
    (with-slots (state hp) e
      (when (and (eq state :alive)
		 (hit? b e))
	(let* ((e-power (max 1 (floor power 2)))
	       (ex (make-instance 'explosion :pos (vec2 (+ (x pos) (x size/2)) (+ (y pos) (y size)))
					     :r (r b) :power e-power)))
	  (push ex (explosions *player*))
	  (delete-obj b (bullets *player*))
	  (bullet-hit-common-action b e))))))

;;ビームがインベーダーに当たった時
(defmethod bullet-hit-action ((b beam-blt) (e invader))
  (with-slots (penetrate power) b
    (with-slots (state hp hit-cd) e
      (when (and (eq state :alive)
		 (hit? b e)
		 (= hit-cd 0))
        (bullet-hit-common-action b e)
	(decf penetrate)
	(incf hit-cd)
	(when (= penetrate 0)
	  (delete-obj b (bullets *player*)))))))

;;弾更新
(defmethod update ((b bullet))
  (with-slots (pos spd) b
    (incf (y pos) (y spd))
    (if (>= (y pos) *window-h*) ;;ウィンドウの外出たら消す
	(delete-obj b (bullets *player*))
	(loop :for wave :in (invaders *invaders*)
	      :do (with-slots (invader-list) wave
		    (loop :for e :in invader-list
			  :do (bullet-hit-action b e)))))))
		      

(defmethod update-tower ((tower wall))
  )


(defmethod update-tower ((tower tower))
  (with-slots (interval atk-c) tower
    (incf atk-c)
    (when (>= atk-c interval)
      (add-bullet tower)
      (setf atk-c 0))))


;;工場更新
(defmethod update-tower ((tower factory))
  (with-slots (inc-money time-c) tower
    (let ((now (get-internal-real-time)))
      (when (>= (- now time-c) 1000)
	(setf time-c now)
	(incf (money *player*) inc-money)))))

;;インベーダーの更新
;; (defmethod update ((e invader))
;;   (with-slots (pos img-pos size) e
;;     (incf (x pos) (x spd))
;;     (incf (y pos) (y spd))
;;     (if (= (x img-pos) 0)
;; 	(setf (x img-pos) (x *invader-size*))
;; 	(setf (x img-pos) 0))))
      


;;爆発の更新
(defmethod update ((e explosion))
  (decf (explosion-time e))
  (if (= (explosion-time e) 0)
      (setf (explosions *player*)
            (remove e (explosions *player*) :test #'equal))
      (loop :for wave :in (invaders *invaders*)
            :do (with-slots (invader-list) wave
		  (loop :for inv :in invader-list
			:do (with-slots (hp state hit-cd) inv
			    (when (and (eq (state inv) :alive)
				       (hit? e inv)
				       (= hit-cd 0))
			      (incf hit-cd)
			      (decf hp (power e))
			      (when (>= 0 hp) 
				(setf state :dead)))))))))

(defun update-explosions ()
  (loop :for explosion :in (explosions *player*)
        :do (update explosion)))

(defun update-towers ()
  (with-slots (towers) *player*
    (loop :for tower :in towers
          :do (update-tower tower))))

;;生きているインベーダーがランダムに弾発射
;; (defun set-alive-invader-shot ()
;;   (let* ((alive (remove :dead (invaders *invaders*) :key #'state))
;; 	 (e (aref alive (random (length alive)))))
;;     (setf (shot e) t)))


(defun update-invader (e wave)
  (with-slots (turn start-turn spd) wave
    (with-slots (pos size img-pos) e
      (incf (x pos) (x spd))
      (incf (y pos) (y spd))
      (if (= (x img-pos) 0)
	  (setf (x img-pos) (x *invader-size*))
	  (setf (x img-pos) 0))
      (when (and (null start-turn)
		 (>= (+ (x pos) (x size) (x spd)) *game-w*))
	(setf start-turn t))
      (when (and start-turn
		 (or (>= (+ (x pos) (x size) (x spd)) *game-w*)
		     (>= 0 (+ (x pos) (x spd)))))
	(setf turn t)))))
	;; (setf (x spd) (- (x spd))
;;       (y spd) -10)))))

(defun delete-dead-invaders (wave)
  (with-slots (invader-list) wave
    (loop :for e :in invader-list
       :do (when (eq (state e) :dead)
	     (delete-obj e invader-list)))))

(defun update-invaders ()
  (with-slots (invaders bullets blt-c bullet-max frame) *invaders*
    (loop :for wave :in invaders
       :do (with-slots (invader-list current invader-max turn spd moved?) wave
	     (loop :for e :in invader-list
		:for num :from 0
		:do (cond
		      ((and (eq (state e) :dead)
			    (= num current))
		       (incf current))
		      ((eq (state e) :alive)
		       (when (> (hit-cd e) 0)
			 (incf (hit-cd e))
			 (when (= (hit-cd e) *hit-cd*)
			   (setf (hit-cd e) 0)))
		       (when (and (< (random (atk-c e)) 1)
				  (zerop (mod frame 3))
				  (> bullet-max (length bullets)))
			 (add-bullet e))
		       (when (and (null moved?)
				  (= num current)
				  (zerop (mod frame (max 1 (floor *invader-max* invader-max)))))
			 (incf current)
			 (setf moved? t)
			 (update-invader e wave)))))
	     ;;(incf current) ;;次に動くインベーダーの番棒
	     (setf moved? nil)
	     (when (>= current invader-max)
	       (delete-dead-invaders wave)
	       (setf current 0
		     invader-max (length invader-list)
		     (y spd) 0)
	       
	       ;;(set-alive-invader-shot)
	       (when turn
		 (setf (x spd) (- (x spd))
		       (y spd) (- -32 (* (wave *player*) 2))
		       turn nil)))))))


(defun update-bullets ()
  (mapc #'update (bullets *invaders*))
  (loop :for bullet :in (bullets *player*)
        :do (update bullet)))


(defun delete-bullet-check (b)
  (with-slots (pos) b
    (or (>= (y pos) (viewport-height))
        (>= 0 (y pos)))))

(defun delete-bullets ()
  (loop :for b :in (bullets *invaders*)
        :do (when (delete-bullet-check b)
              (setf (bullets *invaders*)
                    (remove b (bullets *invaders*) :test #'equal)))))

(defun delete-invader-wave ()
  (loop :for w :in (invaders *invaders*)
	:do (unless (invader-list w)
	      (delete-obj w (invaders *invaders*)))))

;;時間経過で金増える
(defun update-money ()
  (with-slots (money money-c money-t) *player*
    (incf money-c)
    (when (= money-c money-t)
      (incf money)
      (setf money-c 0))))


;;一番高いとこにいるインベーダー

;;インベーダー追加
(defun add-invaders ()
  (with-slots (invaders) *invaders*
    (cond
      ((or (null invaders)
	   (>= 440 (y (pos (car (invader-list (car invaders)))))))
       (incf (wave *player*))
       (create-invaders)))))
    ;; (incf frame)
    ;; (when (zerop (mod frame 2000))
    ;;   (setf frame 0)
;;   (create-invaders))))

;;残ってるタワーの数チェック
(defun tower-check ()
  (let ((c 0)
	(m 0)
	(b 0)
	(f 0))
    (loop :for tower :in (towers *player*)
       :do (case (type-of tower)
	     (canon (incf c))
	     (missile (incf m))
	     (beam (incf b))
	     (factory (incf f))))
    (setf (getf (tower-num *player*) :canon) c
	  (getf (tower-num *player*) :missile) m
	  (getf (tower-num *player*) :beam) b
	  (getf (tower-num *player*) :factory) f)))
  ;;
(defun incf-frame ()
  (incf (frame *invaders*)))

(defmethod gamekit:act ((app mogevader))
  (when (eq (state *player*) :playing)
    (update-bullets)
    (update-invaders)
    (update-towers)
    (update-explosions)
    ;;(hit-invaders-bullets)
    (update-money)
    
    (delete-invader-wave)
    (add-invaders)
    (tower-check)
    (incf-frame)))
  ;;(delete-bullets))

;;
(defmethod gamekit:pre-destroy ((app mogevader))
  (setf *bullets* nil
        *invaders* nil))

(defun run ()
  (gamekit:start 'mogevader)) ;;:viewport-resizable t))
