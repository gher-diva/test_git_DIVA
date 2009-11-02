MODULE templateBasicVector

! ============================================================
! ============================================================
! ============================================================
! ===                                                      ===
! ===                                                      ===
! ===                  Module specifications               ===
! ===                                                      ===
! ===                                                      ===
! ============================================================
! ============================================================
! ============================================================

! Include file
! ============
   USE mathDynamicMemory
   USE templatevectorType
   
! Declaration
! ===========

!  General part
!  ------------
   TYPE (vectorType), PRIVATE, POINTER :: workingVector => NULL()

!  Memory part
!  -----------
   INTEGER, PRIVATE, PARAMETER :: defaultStartingValue = 1
   TYPE (vectorType), PRIVATE :: internalWorkingVector

! Procedures status
! =================

!  General part
!  ------------
   PUBLIC :: printInformation, vectorDestroy, vectorSetSize, vectorGetSize, vectorSetToZero, vectorSetToValue, &
             vectorMin, vectorMax, vectorInsertValue, vectorAddValue, vectorGetValue, &
             vectorCreateBase, vectorCreateWithDimension, vectorCreateWithDimensionAndStartingPoint, vectorGetValues, &
             vectorGetStartIndex, vectorGetEndIndex, setWorkingVector, nullify, vectorSetIncreaseSize, &
             vectorAbsMin, vectorAbsMax

!  Memory part
!  -----------
   PUBLIC ::  memoryGetSize,  memoryGetStartingPoint, memoryGetFinalValuePosition, memoryGetValues
   PRIVATE ::  memorySetSize, memoryAllocateVector, memoryDestructor, &
              memoryPrintInformation, memorySetAllocatedSize, memorySetAllocated, memoryAllocateMemory, memoryGetAllocatedSize, &
              memoryStockIntermediateVector, memoryTransferIntermediateVectorToVector, memoryGetValue, memoryGetAllocationStatus, &
              memoryVectorCreate, memoryGetPointerOnValue, memorySetStartingPoint, memoryGetIncreaseSize, memorySetIncreaseSize

!  Access part
!  -----------
   PRIVATE ::  accessVectorSetToZero, accessVectorSetToValue, accessVectorInsertValue, accessVectorAddValue
   
!  Mathematic part
!  ---------------
   PRIVATE ::  mathVectorMin, mathVectorMax, mathVectorAbsMin, mathVectorAbsMax

! ============================================================
! ============================================================
! ============================================================
! ===                                                      ===
! ===                                                      ===
! ===                  Module procedures                   ===
! ===                                                      ===
! ===                                                      ===
! ============================================================
! ============================================================
! ============================================================
 CONTAINS


! ============================================================
! ============================================================
! ============================================================
! ===                                                      ===
! ===                                                      ===
! ===          Module procedures  : general                ===
! ===                                                      ===
! ===                                                      ===
! ============================================================
! ============================================================
! ============================================================

! ============================================================
! ===            Internal procedure ("PUBLIC")             ===
! ============================================================

! Procedure 1 : setting pointer to vector
! ---------------------------------------
   SUBROUTINE setWorkingVector(targetVector)

!     Declaration
!     - - - - - -
      TYPE(vectorType), INTENT(IN), TARGET :: targetVector

!     Body
!     - - -
      workingVector => targetVector

   END SUBROUTINE

! Procedure 2 : make the target of the pointer null
! --------------------------------------------------
   SUBROUTINE nullify()

!     Body
!     - - -
      workingVector => NULL()

   END SUBROUTINE

! Procedure 3 : create the vector (only vector pointer)
! -------------------------------
   SUBROUTINE vectorCreateBase(targetVector)

!     Pointer filling procedure
!     - - - - - - - - - - - - -
      TYPE(vectorType), INTENT(IN) :: targetVector
      CALL setWorkingVector(targetVector)

!     Body
!     - - -
      CALL memoryVectorCreate()

!     Nullify pointer
!     - - - - - - - -
      CALL nullify()

   END SUBROUTINE

! Procedure 4 : create the vector (with dimension)
! -------------------------------
   SUBROUTINE vectorCreateWithDimension(targetVector, size)

!     Declaration
!     - - - - - -
      INTEGER, INTENT(IN) :: size

!     Pointer filling procedure
!     - - - - - - - - - - - - -
      TYPE(vectorType), INTENT(IN) :: targetVector
      CALL setWorkingVector(targetVector)

!     Body
!     - - -
      CALL memoryVectorCreate()
      CALL memorySetSize(size)
      CALL memoryAllocateVector()

!     Nullify pointer
!     - - - - - - - -
      CALL nullify()

   END SUBROUTINE

! Procedure 5 : create the vector (with dimension and istartingValue)
! -------------------------------
   SUBROUTINE vectorCreateWithDimensionAndStartingPoint(targetVector, size, istartingValue)

!     Declaration
!     - - - - - -
      INTEGER, INTENT(IN) :: size, istartingValue

!     Pointer filling procedure
!     - - - - - - - - - - - - -
      TYPE(vectorType), INTENT(IN) :: targetVector
      CALL setWorkingVector(targetVector)

!     Body
!     - - -
      CALL memoryVectorCreate()
      CALL memorySetStartingPoint(istartingValue)
      CALL memorySetSize(size)
      CALL memoryAllocateVector()

!     Nullify pointer
!     - - - - - - - -
      CALL nullify()

   END SUBROUTINE

! Procedure 6 : get reference to pointer containing the values
! ------------------------------------------------------------

   FUNCTION vectorGetValues(targetVector) RESULT(ptr)

!     Declaration
!     - - - - - -
      VARType, DIMENSION(:), POINTER :: ptr

!     Pointer filling procedure
!     - - - - - - - - - - - - -
      TYPE(vectorType), INTENT(IN) :: targetVector
      CALL setWorkingVector(targetVector)

!     Body
!     - - -
      ptr => memoryGetValues()

!     Nullify pointer
!     - - - - - - - -
      CALL nullify()

   END FUNCTION

! Procedure 7 : print information on the vector
! ---------------------------------------------
   SUBROUTINE printInformation(targetVector)

!     Pointer filling procedure
!     - - - - - - - - - - - - -
      TYPE(vectorType), INTENT(IN) :: targetVector
      CALL setWorkingVector(targetVector)

!     Body
!     - - -
      CALL memoryPrintInformation()

!     Nullify pointer
!     - - - - - - - -
      CALL nullify()

   END SUBROUTINE

! Procedure 8 : destruction of the vector
! ---------------------------------------
   SUBROUTINE vectorDestroy(targetVector)

!     Pointer filling procedure
!     - - - - - - - - - - - - -
      TYPE(vectorType), INTENT(IN) :: targetVector
      CALL setWorkingVector(targetVector)

!     Body
!     - - -
      CALL memoryDestructor()

!     Nullify pointer
!     - - - - - - - -
      CALL nullify()

   END SUBROUTINE

! Procedure 9 : define the size of the vector
! -------------------------------------------
  SUBROUTINE vectorSetSize(targetVector,dim)

!     Declaration
!     - - - - - -
      INTEGER, INTENT(IN) :: dim

!     Pointer filling procedure
!     - - - - - - - - - - - - -
      TYPE(vectorType), INTENT(IN) :: targetVector
      CALL setWorkingVector(targetVector)

!     Body
!     - - -
      CALL memorySetSize(dim)
      CALL memoryAllocateVector()

!     Nullify pointer
!     - - - - - - - -
      CALL nullify()

  END SUBROUTINE

! Procedure 10 : get the size of the vector
! -------------------------------------------
  FUNCTION vectorGetSize(targetVector) RESULT(dim)

!     Declaration
!     - - - - - -
      INTEGER :: dim

!     Pointer filling procedure
!     - - - - - - - - - - - - -
      TYPE(vectorType), INTENT(IN) :: targetVector
      CALL setWorkingVector(targetVector)

!     Body
!     - - -
      dim = memoryGetSize()

!     Nullify pointer
!     - - - - - - - -
      CALL nullify()

  END FUNCTION

! Procedure 11 : set 0 to each entry
! ---------------------------------
  SUBROUTINE vectorSetToZero(targetVector)

!     Pointer filling procedure
!     - - - - - - - - - - - - -
      TYPE(vectorType), INTENT(IN) :: targetVector
      CALL setWorkingVector(targetVector)

!     Body
!     - - -
      CALL accessVectorSetToZero()

!     Nullify pointer
!     - - - - - - - -
      CALL nullify()

  END SUBROUTINE

! Procedure 12 : set "value" to each entry
! ---------------------------------------
  SUBROUTINE vectorSetToValue(targetVector,val)

!     Declaration
!     - - - - - -
      VARType, INTENT(IN) :: val

!     Pointer filling procedure
!     - - - - - - - - - - - - -
      TYPE(vectorType), INTENT(IN) :: targetVector
      CALL setWorkingVector(targetVector)

!     Body
!     - - -
      CALL accessVectorSetToValue(val)

!     Nullify pointer
!     - - - - - - - -
      CALL nullify()

  END SUBROUTINE

! Procedure 13 : min value
! -----------------------
  FUNCTION vectorMin(targetVector) RESULT(val)

!     Declaration
!     - - - - - -
      VARType :: val

!     Pointer filling procedure
!     - - - - - - - - - - - - -
      TYPE(vectorType), INTENT(IN) :: targetVector
      CALL setWorkingVector(targetVector)

!     Body
!     - - -
      val = mathVectorMin()

!     Nullify pointer
!     - - - - - - - -
      CALL nullify()

  END FUNCTION

! Procedure 14 : max value
! -----------------------
  FUNCTION vectorMax(targetVector) RESULT(val)

!     Declaration
!     - - - - - -
      VARType :: val

!     Pointer filling procedure
!     - - - - - - - - - - - - -
      TYPE(vectorType), INTENT(IN) :: targetVector
      CALL setWorkingVector(targetVector)

!     Body
!     - - -
      val = mathVectorMax()

!     Nullify pointer
!     - - - - - - - -
      CALL nullify()

  END FUNCTION

! Procedure 15 : insert value in vector (scracth the previous one)
! ---------------------------------------------------------------
  SUBROUTINE vectorInsertValue(targetVector,position,val)

!     Declaration
!     - - - - - -
      INTEGER, INTENT(IN) :: position
      VARType, INTENT(IN) :: val

!     Pointer filling procedure
!     - - - - - - - - - - - - -
      TYPE(vectorType), INTENT(IN) :: targetVector
      CALL setWorkingVector(targetVector)

!     Body
!     - - -
      CALL accessVectorInsertValue(position,val)

!     Nullify pointer
!     - - - - - - - -
      CALL nullify()

  END SUBROUTINE

! Procedure 16 : add value in vector (value = old value + new value)
! -----------------------------------------------------------------
  SUBROUTINE vectorAddValue(targetVector,position,val)

!     Declaration
!     - - - - - -
      INTEGER, INTENT(IN) :: position
      VARType, INTENT(IN) :: val

!     Pointer filling procedure
!     - - - - - - - - - - - - -
      TYPE(vectorType), INTENT(IN) :: targetVector
      CALL setWorkingVector(targetVector)

!     Body
!     - - -
      CALL accessVectorAddValue(position,val)

!     Nullify pointer
!     - - - - - - - -
      CALL nullify()

  END SUBROUTINE

! Procedure 17 : get the value in the vector
! ------------------------------------------
  FUNCTION vectorGetValue(targetVector,i1) RESULT(val)

!     Declaration
!     - - - - - -
      INTEGER, INTENT(IN) :: i1
      VARType :: val

!     Pointer filling procedure
!     - - - - - - - - - - - - -
      TYPE(vectorType), INTENT(IN) :: targetVector
      CALL setWorkingVector(targetVector)

!     Body
!     - - -
      val = memoryGetValue(i1)

!     Nullify pointer
!     - - - - - - - -
      CALL nullify()

  END FUNCTION

! Procedure 18 : get start index
! ------------------------------
  FUNCTION vectorGetStartIndex(targetVector) RESULT(i1)

!     Declaration
!     - - - - - -
      INTEGER :: i1

!     Pointer filling procedure
!     - - - - - - - - - - - - -
      TYPE(vectorType), INTENT(IN) :: targetVector
      CALL setWorkingVector(targetVector)

      i1 = memoryGetStartingPoint()

  END FUNCTION

! Procedure 19 : get end index
! ------------------------------
  FUNCTION vectorGetEndIndex(targetVector,istart) RESULT(i1)

!     Declaration
!     - - - - - -
      INTEGER, INTENT(IN) :: istart
      INTEGER :: i1

!     Pointer filling procedure
!     - - - - - - - - - - - - -
      TYPE(vectorType), INTENT(IN) :: targetVector
      CALL setWorkingVector(targetVector)

      i1 = memoryGetFinalValuePosition(memoryGetSize(),istart)

  END FUNCTION

! Procedure 20 : define the increase size
! ----------------------------------------
  SUBROUTINE vectorSetIncreaseSize(targetVector,size)
  
!     Declaration
!     - - - - - -
      INTEGER, INTENT(IN) :: size
      INTEGER :: dim

!     Pointer filling procedure
!     - - - - - - - - - - - - -
      TYPE(vectorType), INTENT(IN) :: targetVector
      CALL setWorkingVector(targetVector)

      dim = size
      
      IF ( size < 0 ) THEN
         dim = memoryGetDefaultIncreaseSize()
      END IF
      
      CALL memorySetIncreaseSize(dim)
      
  END SUBROUTINE
  
! Procedure 21 : min abs(value)
! -----------------------
  FUNCTION vectorAbsMin(targetVector) RESULT(val)

!     Declaration
!     - - - - - -
      VARType :: val

!     Pointer filling procedure
!     - - - - - - - - - - - - -
      TYPE(vectorType), INTENT(IN) :: targetVector
      CALL setWorkingVector(targetVector)

!     Body
!     - - -
      val = mathVectorAbsMin()

!     Nullify pointer
!     - - - - - - - -
      CALL nullify()

  END FUNCTION

! Procedure 22 : max abs(value)
! -----------------------
  FUNCTION vectorAbsMax(targetVector) RESULT(val)

!     Declaration
!     - - - - - -
      VARType :: val

!     Pointer filling procedure
!     - - - - - - - - - - - - -
      TYPE(vectorType), INTENT(IN) :: targetVector
      CALL setWorkingVector(targetVector)

!     Body
!     - - -
      val = mathVectorAbsMax()

!     Nullify pointer
!     - - - - - - - -
      CALL nullify()

  END FUNCTION

! ============================================================
! ============================================================
! ============================================================
! ===                                                      ===
! ===                                                      ===
! ===          Module procedures  : memory                 ===
! ===                                                      ===
! ===                                                      ===
! ============================================================
! ============================================================
! ============================================================

! ============================================================
! ===            Internal procedure ("PUBLIC")             ===
! ============================================================


! Procedure 1 : define the size of the vector
! -------------------------------------------
   SUBROUTINE memorySetSize(ivalue)

!     Declaration
!     - - - - - -
      INTEGER, INTENT(IN) :: ivalue

!     Body
!     - - -
      workingVector%nbOfData = ivalue

   END SUBROUTINE

! Procedure 2 : define the allocated size of the vector
! ------------------------------------------------------
   SUBROUTINE memorySetAllocatedSize(ivalue)

!     Declaration
!     - - - - - -
      INTEGER, INTENT(IN) :: ivalue

!     Body
!     - - -
      workingVector%allocatedSize = ivalue

   END SUBROUTINE

! Procedure 3 : define the allocation status of the vector
! --------------------------------------------------------
   SUBROUTINE memorySetAllocated(icheck)

!     Declaration
!     - - - - - -
      LOGICAL, INTENT(IN) :: icheck

!     Body
!     - - -
      workingVector%isAllocated = icheck

   END SUBROUTINE

! Procedure 4 : allocated memory to the vector
! --------------------------------------------
   SUBROUTINE memoryAllocateVector()

!     Declaration
!     - - - - - -
      INTEGER :: newSize, istartValue, istart
      INTEGER, DIMENSION(1) :: istartTab

!     Body
!     - - -
      SELECT CASE (memoryGetAllocationStatus())
         CASE (.TRUE.)
            istartTab = lbound(workingVector%values)
            istart = istartTab(1)
            istartValue = memoryGetStartingPoint()

            IF ((memoryGetSize() >= memoryGetAllocatedSize()).OR.(istartValue<istart)) THEN
                newSize = memoryGetSize()
                CALL memoryStockIntermediateVector()
                CALL memoryDestructor()
                CALL memorySetStartingPoint(istartValue)
                CALL memorySetAllocatedSize(newSize+memoryGetIncreaseSize())
                CALL memorySetSize(newSize)
                CALL memoryAllocateMemory()
                CALL memoryTransferIntermediateVectorToVector()
            END IF
         CASE (.FALSE.)
            CALL memoryFirstAllocateMemory()
      END SELECT

   END SUBROUTINE

! Procedure 5 : allocated memory to the vector
! ---------------------------------------------
  SUBROUTINE memoryAllocateMemory()

!     Declaration
!     - - - - - -
      INTEGER :: istart, iend
      
!     Body
!     - - -
      istart = memoryGetStartingPoint()
      iend = memoryGetFinalValuePosition(memoryGetAllocatedSize(),istart)
      
      ALLOCATE(workingVector%values(istart:iend))
      CALL memorySetAllocated(true)

  END SUBROUTINE

! Procedure 6 : allocated memory to the vector
! ---------------------------------------------
  SUBROUTINE memoryFirstAllocateMemory()

!     Declaration
!     - - - - - -
      INTEGER :: istart, iend

!     Body
!     - - -
      CALL memorySetAllocatedSize(ione)

      istart = memoryGetStartingPoint()
      iend = memoryGetFinalValuePosition(memoryGetAllocatedSize(),istart)

      ALLOCATE(workingVector%values(istart:iend))
      CALL memorySetAllocated(true)

  END SUBROUTINE

! Procedure 7 : getting the allocated memory size
! ------------------------------------------------
  FUNCTION memoryGetAllocatedSize() RESULT(size)

!     Declaration
!     - - - - - -
      INTEGER :: size

!     Body
!     - - -
      size = workingVector%allocatedSize

   END FUNCTION

! Procedure 8 : getting the vector size
! --------------------------------------
  FUNCTION memoryGetSize() RESULT(size)

!     Declaration
!     - - - - - -
      INTEGER :: size

!     Body
!     - - -
      size = workingVector%nbOfData

   END FUNCTION

! Procedure 9 : transfer data from workingVector to secondWorkingVector
! ----------------------------------------------------------------------
  SUBROUTINE memoryStockIntermediateVector()

!     Declaration
!     - - - - - -
      INTEGER :: i1, istart,iend
      INTEGER, DIMENSION(1) :: istartTab,iendTab

!     Body
!     - - -
      istartTab = lbound(workingVector%values)
      iendTab = ubound(workingVector%values)
      istart = istartTab(1)
      iend = iendTab(1)
      
      ALLOCATE(internalWorkingVector%values(istart:iend))

      DO i1 = istart , iend
         internalWorkingVector%values(i1) = workingVector%values(i1)
      END DO

  END SUBROUTINE

! Procedure 10 : transfer data from secondWorkingVector to workingVector
! -----------------------------------------------------------------------
  SUBROUTINE memoryTransferIntermediateVectorToVector()

!     Declaration
!     - - - - - -
      INTEGER :: i1, istart,iend
      INTEGER, DIMENSION(1) :: istartTab,iendTab

!     Body
!     - - -
      istartTab = lbound(internalWorkingVector%values)
      iendTab = ubound(internalWorkingVector%values)
      istart = istartTab(1)
      iend = iendTab(1)

      DO i1 = istart , iend
         workingVector%values(i1) = internalWorkingVector%values(i1)
      END DO

      DEALLOCATE(internalWorkingVector%values)

  END SUBROUTINE

! Procedure 11 : deallocation of the memory
! ------------------------------------------
  SUBROUTINE memoryDestructor()

!     Body
!     - - -
      DEALLOCATE(workingVector%values)
      workingVector%values => NULL()
      CALL memorySetSize(izero)
      CALL memorySetAllocatedSize(izero)
      CALL memorySetIncreaseSize(memoryGetDefaultIncreaseSize())
      CALL memorySetStartingPoint(ione)
      CALL memorySetAllocated(false)

  END SUBROUTINE

! Procedure 12 : get the value in the vector
! ------------------------------------------
  FUNCTION memoryGetValue(i1) RESULT(val)

!     Declaration
!     - - - - - -
      INTEGER, INTENT(IN) :: i1
      VARType :: val

!     Body
!     - - -
      val = workingVector%values(i1)

  END FUNCTION

! Procedure 13 : get the allocation status
! ----------------------------------------
  FUNCTION memoryGetAllocationStatus() RESULT(status)

!     Declaration
!     - - - - - -
      LOGICAL :: status

!     Body
!     - - -
      status = workingVector%isAllocated

  END FUNCTION

! Procedure 14 : print information on the vector
! ---------------------------------------------
   SUBROUTINE memoryPrintInformation()

!     Declaration
!     - - - - - -
      INTEGER :: i1, istart, iend

!     Body
!     - - -
      istart = memoryGetStartingPoint()
      iend = memoryGetFinalValuePosition(memoryGetSize(),istart)


      WRITE(stdOutput,*) 'The size of the vector is : ', memoryGetSize()
      WRITE(stdOutput,*) '   The allocated memory is : ', memoryGetAllocatedSize()
      WRITE(stdOutput,*) '   The increase allocation memory is : ', memoryGetIncreaseSize()
      WRITE(stdOutput,*) '   Allocation status of the vector : ', memoryGetAllocationStatus()
      WRITE(stdOutput,*) '   First position is : ', memoryGetStartingPoint()
      WRITE(stdOutput,*) '   Last position is  : ', memoryGetFinalValuePosition(memoryGetSize(),memoryGetStartingPoint())

      IF (memoryGetAllocationStatus()) THEN
         DO i1 = istart, iend
            WRITE(stdOutput,*) 'value(',i1, ') = ', memoryGetValue(i1)
         ENDDO
      END IF

   END SUBROUTINE

! Procedure 15 : create the vector
! ---------------------------------
   SUBROUTINE memoryVectorCreate()

!     Body
!     - - -
      CALL memorySetStartingPoint(defaultStartingValue)
      CALL memorySetSize(izero)
      CALL memorySetIncreaseSize(memoryGetDefaultIncreaseSize())
      CALL memorySetAllocatedSize(memoryGetIncreaseSize())
      CALL memorySetAllocated(false)
      CALL memoryAllocateVector()

   END SUBROUTINE

! Procedure 16 : get the pointer on a value
! -----------------------------------------
  FUNCTION memoryGetPointerOnValue(position) RESULT(ptr)

!     Declaration
!     - - - - - -
      INTEGER, INTENT(IN) :: position
      VARType, POINTER :: ptr

!     Body
!     - - -
      ptr => workingVector%values(position)

  END FUNCTION
  
! Procedure 17 : set the starting point of the vector
! ---------------------------------------------------
  SUBROUTINE memorySetStartingPoint(ivalue)

!     Declaration
!     - - - - - -
      INTEGER, INTENT(IN) :: ivalue

!     Body
!     - - -
      workingVector%startValue = ivalue
      
  END SUBROUTINE
  
! Procedure 18 : get the starting point of the vector
! ---------------------------------------------------
  FUNCTION memoryGetStartingPoint() RESULT(ivalue)

!     Declaration
!     - - - - - -
      INTEGER :: ivalue

!     Body
!     - - -
      ivalue = workingVector%startValue

  END FUNCTION

! Procedure 19 : get the final position in the vector with respect to given dimension
! -----------------------------------------------------------------------------------
  FUNCTION memoryGetFinalValuePosition(dim, start) RESULT(ivalue)
  
!     Declaration
!     - - - - - -
      INTEGER, INTENT(IN) :: dim, start
      INTEGER :: ivalue

!     Body
!     - - -
      ivalue = dim + start - 1

  END FUNCTION

! Procedure 20 : get reference to pointer containing the values
! ------------------------------------------------------------
   FUNCTION memoryGetValues() RESULT(ptr)

!     Pointer filling procedure
!     - - - - - - - - - - - - -
      VARType, DIMENSION(:), POINTER :: ptr

!     Body
!     - - -
      ptr => workingVector%values

   END FUNCTION

! Procedure 21 : set the increase size for memory allocation
! ----------------------------------------------------------
  SUBROUTINE memorySetIncreaseSize(size)
  
!     Declaration
!     - - - - - -
      INTEGER, INTENT(IN) :: size

!     Body
!     - - -
      workingVector%increaseSize = size
      
  END SUBROUTINE
  
! Procedure 22 : get the increase size for memory allocation
! ----------------------------------------------------------
  FUNCTION memoryGetIncreaseSize() RESULT(size)

!     Declaration
!     - - - - - -
      INTEGER :: size

!     Body
!     - - -
      size = workingVector%increaseSize

  END FUNCTION

! ============================================================
! ============================================================
! ============================================================
! ===                                                      ===
! ===                                                      ===
! ===          Module procedures : access                  ===
! ===                                                      ===
! ===                                                      ===
! ============================================================
! ============================================================
! ============================================================

! ============================================================
! ===            Internal procedure ("PUBLIC")             ===
! ============================================================


! Procedure 1 : set 0 to each entry
! ---------------------------------
  SUBROUTINE accessVectorSetToZero()

!     Declaration
!     - - - - - -
      VARType, PARAMETER :: val = 0

!     Body
!     - - -
      CALL accessVectorSetToValue(val)

  END SUBROUTINE

! Procedure 2 : set "value" to each entry
! ---------------------------------------
  SUBROUTINE accessVectorSetToValue(val)

!     Declaration
!     - - - - - -
      INTEGER :: i1, istart, iend
      VARType, INTENT(IN) :: val
      VARType, DIMENSION(:), POINTER :: ptr

!     Body
!     - - -
      istart = memoryGetStartingPoint()
      iend = memoryGetFinalValuePosition(memoryGetSize(),istart)

      ptr =>  memoryGetValues()

      DO i1 = istart , iend
           ptr(i1) = val
      END DO

  END SUBROUTINE

! Procedure 3 : insert value in vector (scracth the previous one)
! ---------------------------------------------------------------
  SUBROUTINE accessVectorInsertValue(position,val)

!     Declaration
!     - - - - - -
      INTEGER, INTENT(IN) :: position
      INTEGER :: istart, iend
      VARType, INTENT(IN) :: val

!     Body
!     - - -
      istart = memoryGetStartingPoint()
      IF ( position < istart ) THEN
         CALL memorySetStartingPoint(position)
         CALL memorySetSize(istart-position+memoryGetSize())
         CALL memoryAllocateVector()
         GOTO 30
      ENDIF
      
      iend = memoryGetFinalValuePosition(memoryGetSize(),istart)
      IF ( position > iend ) THEN
         CALL memorySetSize(position-iend + memoryGetSize())
         CALL memoryAllocateVector()
      ENDIF

30    CONTINUE
      workingVector%values(position) = val

  END SUBROUTINE

! Procedure 4 : add value in vector (value = old value + new value)
! -----------------------------------------------------------------
  SUBROUTINE accessVectorAddValue(position,val)

!     Declaration
!     - - - - - -
      INTEGER, INTENT(IN) :: position
      INTEGER :: istart, iend
      VARType, INTENT(IN) :: val
      VARType, POINTER :: ptr

!     Body
!     - - -
      istart = memoryGetStartingPoint()
      IF ( position < istart ) RETURN
      
      iend = memoryGetFinalValuePosition(memoryGetSize(),istart)
      IF ( position > iend ) RETURN

      ptr => memoryGetPointerOnValue(position)
      ptr = ptr + val

  END SUBROUTINE

! ============================================================
! ============================================================
! ============================================================
! ===                                                      ===
! ===                                                      ===
! ===          Module procedures : mathematic              ===
! ===                                                      ===
! ===                                                      ===
! ============================================================
! ============================================================
! ============================================================

! ============================================================
! ===            Internal procedure ("PUBLIC")             ===
! ============================================================

! Procedure 1 : min value
! -----------------------
  FUNCTION mathVectorMin() RESULT(val)

!     Declaration
!     - - - - - -
      INTEGER :: i1, istart, iend
      VARType :: val
      VARType, DIMENSION(:), POINTER :: ptr

!     Body
!     - - -
      istart = memoryGetStartingPoint()
      iend = memoryGetFinalValuePosition(memoryGetSize(),istart)

      ptr =>  memoryGetValues()
      
      val = ptr(istart)

      DO i1 = istart + 1 , iend
         val = min(val,ptr(i1))
      END DO

  END FUNCTION

! Procedure 2 : max value
! -----------------------
  FUNCTION mathVectorMax() RESULT(val)

!     Declaration
!     - - - - - -
      INTEGER :: i1, istart, iend
      VARType :: val
      VARType, DIMENSION(:), POINTER :: ptr

!     Body
!     - - -
      istart = memoryGetStartingPoint()
      iend = memoryGetFinalValuePosition(memoryGetSize(),istart)

      ptr =>  memoryGetValues()

      val = ptr(istart)

      DO i1 = istart + 1, iend
         val = max(val,ptr(i1))
      END DO

  END FUNCTION

! Procedure 3 : min abs(value)
! ----------------------------
  FUNCTION mathVectorAbsMin() RESULT(val)

!     Declaration
!     - - - - - -
      INTEGER :: i1, istart, iend
      VARType :: val
      VARType, DIMENSION(:), POINTER :: ptr

!     Body
!     - - -
      istart = memoryGetStartingPoint()
      iend = memoryGetFinalValuePosition(memoryGetSize(),istart)

      ptr =>  memoryGetValues()

      val = abs(ptr(istart))

      DO i1 = istart + 1 , iend
         val = min(val,abs(ptr(i1)))
      END DO

  END FUNCTION

! Procedure 4 : max abs(value)
! ---------------------------
  FUNCTION mathVectorAbsMax() RESULT(val)

!     Declaration
!     - - - - - -
      INTEGER :: i1, istart, iend
      VARType :: val
      VARType, DIMENSION(:), POINTER :: ptr

!     Body
!     - - -
      istart = memoryGetStartingPoint()
      iend = memoryGetFinalValuePosition(memoryGetSize(),istart)

      ptr =>  memoryGetValues()

      val = abs(ptr(istart))

      DO i1 = istart + 1, iend
         val = max(val,abs(ptr(i1)))
      END DO

  END FUNCTION

END MODULE templateBasicVector

