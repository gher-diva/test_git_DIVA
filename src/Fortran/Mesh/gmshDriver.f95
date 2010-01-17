PROGRAM gmshDriver

! This program is a driver from diva data to GMSH data file in order
! to make the meshing procedure with GMSH.
!

! Module to use
! =============
 USE moduleDIVA
 USE moduleFile
 USE vectorInterface
 USE stencilInterface
 USE nodeInterface
 USE contourInterface
 USE lineInterface
 USE tria3Interface
 USE moduleCoordinateInformation, initialiseCoordinateInformation => initialise


 INCLUDE 'iodv.h'

!     Declaration
!     ===========
!        General
!        -------
         INTEGER :: i1, i2, fileUnit
         REAL(KIND=8) :: deltaXInKm, deltaYInKm, Xmin, Xmax, Ymin, Ymax
         REAL(KIND=8) :: changeCoordinate
         REAL(KIND=8), PARAMETER :: one = 1., zero = 0.

         REAL(KIND=8) :: meshCharacteristicLength
         TYPE(file) :: inputGeneralFile

!        Boundary
!        --------
         INTEGER :: nbOfContour, nbOfNodeInBoundaryI1
         INTEGER, TARGET :: boundaryNodeIndex
         INTEGER, POINTER :: boundarySegmentIndex

         TYPE(contourDataBase) :: boundaryLoops
         TYPE(contour), POINTER :: ptrBoundaryLoop

         TYPE(line) :: lineElement
         TYPE(line), POINTER :: ptrLine
         TYPE(lineDataBase), POINTER :: ptrBoundaryLoopSegment

         TYPE(node) :: nodeElement = node(0.,0.,0.,0,0.)
         TYPE(node), TARGET :: nodeElement1 = node(0.,0.,0.,0,0.), nodeElementOld = node(0.,0.,0.,0,0.)
         TYPE(node), POINTER :: ptrNode, ptrNode1

         TYPE(file) :: inputCoastFile

!        GMSH
!        ----
         TYPE(file) :: outputGMSHFile, outputGMSHMeshFile

!        Reload result
!        -------------
         INTEGER, PARAMETER :: waitingTime = 5, informationLine = 3, defaultIncrease = 1000

         INTEGER :: nbOfVertices, nbOfCell, localNbOfCell, localNbOfVertices
         REAL(KIND=8) :: lengthX, lengthY
         TYPE(nodeDataBase) :: vertices
         TYPE(tria3DataBase) :: cells
         TYPE(tria3), POINTER :: ptrCell

! ==================================================================================
! ==================================================================================
!  Start Diva mesh code
! ==================================================================================
! ==================================================================================
      CALL createDIVAContext()
      CALL initialiseCoordinateInformation()
      CALL setGmshWithCoastRefinement(.TRUE.)

! ==================================================================================
! ==================================================================================
!  General information
! ==================================================================================
! ==================================================================================

!  Defined file name and open the file
!  ====================================
   CALL createFile(inputGeneralFile,'fort.11',formType=STD_FORMATTED)

   IF ( iodv == 1 ) THEN
      CALL defineFileName(inputGeneralFile,'meshgen.prm')
   ENDIF

   CALL openFile(inputGeneralFile)
   fileUnit = getFileUnit(inputGeneralFile)

! Read data
! =========
   READ(fileUnit,*)
   READ(fileUnit,*) meshCharacteristicLength

   CALL closeFile(inputGeneralFile)

! ==================================================================================
! ==================================================================================
!  Read Coast (Boundary)
! ==================================================================================
! ==================================================================================

!  Defined file name and open the file
!  ====================================
   CALL createFile(inputCoastFile,'fort.10',formType=STD_FORMATTED)

   IF ( iodv == 1 ) THEN
      CALL defineFileName(inputCoastFile,'domain.checked')
   ENDIF

   CALL openFile(inputCoastFile)
   fileUnit = getFileUnit(inputCoastFile)

!  Read the boundaries (coast) of the computational domain
!  =======================================================

      Xmin = 1.D9
      Xmax = -1.D9
      Ymin = 1.D9
      Ymax = -1.D9

!     Read the number of boundaries and create the data base
!     ------------------------------------------------------
      READ(fileUnit,*) nbOfContour
      CALL contourDBCreate(boundaryLoops,nbOfContour)

!     General loop to read the boundaries
!     -----------------------------------
      boundaryNodeIndex = 0
      boundarySegmentIndex => boundaryNodeIndex

      DO i1 = 1, nbOfContour

!         Read the number of "potential" element in the boundary loop
!         +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
          ptrBoundaryLoop => contourDBGetValue(boundaryLoops,i1) ! take a pointer on the i1_th boundary loop in the data base
          READ(fileUnit,*) nbOfNodeInBoundaryI1                  ! read the number of nodes describing the boundary

!         Define "potential" dimension of the data base containing the boundary segments
!         ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
          ptrBoundaryLoopSegment => ptrBoundaryLoop%lineDB

          CALL lineDBAddSize(ptrBoundaryLoopSegment,nbOfNodeInBoundaryI1) ! reserve memory to store the segments of the boundary

!         Read the segments of the boundary
!         +++++++++++++++++++++++++++++++++
!            Read the first segment
!            - - - - - - - - - - - -
             boundaryNodeIndex = boundaryNodeIndex + 1
             nodeElement1%indexValue = boundaryNodeIndex

             READ(fileUnit,*) nodeElement1%xValue, nodeElement1%yValue
             lineElement%startNode = nodeElement1
             lineElement%indexValue = boundarySegmentIndex

             ptrNode1 => nodeElement1
             ptrNode => nodeElementOld
             ptrNode%xValue = ptrNode1%xValue
             ptrNode%yValue = ptrNode1%yValue

             Xmin = min(Xmin,ptrNode1%xValue)
             Xmax = max(Xmax,ptrNode1%xValue)
             Ymin = min(Ymin,ptrNode1%yValue)
             Ymax = max(Ymax,ptrNode1%yValue)

!            Read the following segments
!            - - - - - - - - - - - - - -
             DO i2 = 2 , nbOfNodeInBoundaryI1 - 1

!                Read the node coordinates
!                + + + + + + + + + + + + + +
                 READ(fileUnit,*) nodeElement%xValue, nodeElement%yValue

!                Check if this node is not identical to the previous one
!                + + + + + + + + + + + + + + + + + + + + + + + + + + + +

                 IF ( checkNewNode(ptrNode,nodeElement) ) THEN

                      boundaryNodeIndex = boundaryNodeIndex + 1
                      nodeElement%indexValue = boundaryNodeIndex

                      lineElement%endNode = nodeElement

                      CALL lineDBFastPushBack(ptrBoundaryLoopSegment,lineElement) ! introduction of the segment in the database

                      lineElement%startNode = nodeElement
                      lineElement%indexValue = boundarySegmentIndex

                      ptrNode%xValue = nodeElement%xValue
                      ptrNode%yValue = nodeElement%yValue

                     Xmin = min(Xmin,ptrNode%xValue)
                     Xmax = max(Xmax,ptrNode%xValue)
                     Ymin = min(Ymin,ptrNode%yValue)
                     Ymax = max(Ymax,ptrNode%yValue)

                 ENDIF

             ENDDO

!            Read the last segment
!            - - - - - - - - - - -
!                Read the node coordinates
!                + + + + + + + + + + + + + +
            READ(fileUnit,*) nodeElement%xValue, nodeElement%yValue

!                Check if this node is not identical to the previous one
!                + + + + + + + + + + + + + + + + + + + + + + + + + + + +
            IF ( checkNewNode(ptrNode,nodeElement) ) THEN

                    Xmin = min(Xmin,nodeElement%xValue)
                    Xmax = max(Xmax,nodeElement%xValue)
                    Ymin = min(Ymin,nodeElement%yValue)
                    Ymax = max(Ymax,nodeElement%yValue)


!                   Check of this node is not identical to the first node
!                   -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
                    IF ( checkNewNode(ptrNode1,nodeElement) ) THEN

                         boundaryNodeIndex = boundaryNodeIndex + 1
                         nodeElement%indexValue = boundaryNodeIndex

                         lineElement%endNode = nodeElement

                         CALL lineDBFastPushBack(ptrBoundaryLoopSegment,lineElement) ! introduction of the segment in the database

                         lineElement%startNode = nodeElement
                         lineElement%indexValue = boundarySegmentIndex
                         lineElement%endNode = ptrNode1

                         CALL lineDBFastPushBack(ptrBoundaryLoopSegment,lineElement) ! introduction of the segment in the database

                    ELSE

                         lineElement%endNode = ptrNode1
                         CALL lineDBFastPushBack(ptrBoundaryLoopSegment,lineElement) ! introduction of the segment in the database

                    ENDIF


            ELSE

!                   Check of this node is not identical to the first node
!                   -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
                    IF ( checkNewNode(ptrNode1,nodeElement) ) THEN

                         lineElement%endNode = ptrNode1
                         CALL lineDBFastPushBack(ptrBoundaryLoopSegment,lineElement) ! introduction of the segment in the database

                    ELSE
                         ptrLine => lineDBGetPointerOnLastValue(ptrBoundaryLoopSegment)
                         ptrLine%endNode = ptrNode1
                    ENDIF

            ENDIF

      ENDDO

!  Close the file
!  ==============
   CALL closeFile(inputCoastFile)

! ==================================================================================
! ==================================================================================
! Search domain to be meshed
! ==================================================================================
! ==================================================================================

   CALL searchDomainToBeMeshed(boundaryLoops)

! ==================================================================================
! ==================================================================================
! Now implement coordinate change on the N points and Density regions if ncessessary
! ==================================================================================
! ==================================================================================

   READ(5,*,ERR=9911,END=9911) changeCoordinate

   IF ( changeCoordinate > 0. ) THEN
      CALL setIChangeCoordinate(1)
   ENDIF

   IF ( changeCoordinate > 1.5 ) THEN
      PRINT*,'Pseudo-spherical'
      CALL setISpheric(1)
   ENDIF

   IF ( changeCoordinate < 0. ) THEN
      CALL setIChangeCoordinate(-1)
   ENDIF

9911 CONTINUE

    PRINT*,'Coordinates ', getIChangeCoordinate(), getISpheric(), changeCoordinate

    CALL setMinimumLongitude(Xmin)
    CALL setMaximumLongitude(Xmax)
    CALL setMinimumLatitude(Ymin)
    CALL setMaximumLatitude(Ymax)
    CALL computeMeanLongitude()
    CALL computeMeanLatitude()

    IF ( getIChangeCoordinate() < 0 ) THEN
      PRINT*,'Anisotropic case'
      CALL setDeltaYInKm(one)
      CALL setDeltaXInKm((-1.)*changeCoordinate)
    ENDIF

    IF ( getIChangeCoordinate() == 1 ) THEN

      deltaYInKm = ( 4. * asin(1.) * 6360. ) / 360.
      deltaXInKm = asin(1.) * getMeanLatitude() / 90.
      deltaXInKm = 6360. * cos( deltaXInKm )
      deltaXInKm = ( 4. * asin(1.) * deltaXInKm ) / 360.

      CALL setDeltaXInKm(deltaXInKm)
      CALL setDeltaYInKm(deltaYInKm)

      IF ( getISpheric() /= 1 ) THEN
         meshCharacteristicLength = meshCharacteristicLength * deltaYInKm
      ENDIF
    ENDIF

    IF ( getISpheric() == 1 ) THEN
      PRINT*,'Spherical case'
      CALL setMeanLatitude(zero)
      CALL setDeltaXInKm(one)
      CALL setDeltaYInKm(one)
      PRINT*,'Mean longitude',getMeanLongitude()
    ENDIF


    IF ( getIChangeCoordinate() /= 0 ) THEN

      DO i1 = 1, nbOfContour

          ptrBoundaryLoop => contourDBGetValue(boundaryLoops,i1) ! take a pointer on the i1_th boundary loop in the data base
          ptrBoundaryLoopSegment => ptrBoundaryLoop%lineDB
          CALL changeLongLatToXY(ptrBoundaryLoopSegment)

      ENDDO

    END IF

! ==================================================================================
! ==================================================================================
! Now here, subtract mean coordinate position to enhance numerical
! precision on mesh-generation
! ==================================================================================
! ==================================================================================

    CALL computeMeanCoordinate(boundaryLoops)
    PRINT*, 'Now centering coordinates ',getMeanXCoordinate(), getMeanYCoordinate()

    CALL computeDimensionLessLength()
    PRINT*,'characteristicLength ',getDimensionLessLength()
    meshCharacteristicLength = meshCharacteristicLength / getDimensionLessLength()

    CALL shiftAllCoordinate(boundaryLoops)
    CALL shiftMinimumLongitude()
    CALL shiftMinimumLatitude()
    CALL shiftMaximumLongitude()
    CALL shiftMaximumLatitude()


! ==================================================================================
! ==================================================================================
! Export boundary to gmsh and run
! ==================================================================================
! ==================================================================================

#ifdef _WITH_GMSH_
     CALL createFile(outputGMSHFile,'diva.geo',formType=STD_FORMATTED)
     CALL createFile(outputGMSHMeshFile,'diva.msh',formType=STD_FORMATTED)
     CALL exportBoundaryToGMSH(outputGMSHFile,boundaryLoops,meshCharacteristicLength)
     CALL runGMSH(outputGMSHFile,outputGMSHMeshFile)


! ==================================================================================
! ==================================================================================
! read the result
! ==================================================================================
! ==================================================================================

   CALL sleep(waitingTime)

!  Defined file name and open the file
!  ====================================
   CALL openFile(outputGMSHMeshFile)
   fileUnit = getFileUnit(outputGMSHMeshFile)

!  Read the resulting mesh
!  =======================
!     Read information
!     ----------------
      DO i1 = 1, informationLine
          READ(fileUnit,*)
      ENDDO

!     Read vertices
!     -------------
      READ(fileUnit,*)

      READ(fileUnit,*) nbOfVertices
      CALL nodeDBCreate(vertices,nbOfVertices)

      DO i1 = 1, nbOfVertices
         ptrNode => vertices%values(i1)
         READ(fileUnit,*) ptrNode%indexValue, ptrNode%xValue, ptrNode%yValue, ptrNode%zValue
      ENDDO

      READ(fileUnit,*)

!     Read information
!     ----------------
      READ(fileUnit,*)

      READ(fileUnit,*) nbOfCell
      CALL tria3DBCreate(cells,nbOfCell)
      DO i1 = 1, nbOfCell
          ptrCell => cells%values(i1)
          READ(fileUnit,*) ptrCell%indexValue,i2,i2,i2,i2,ptrCell%node1,ptrCell%node2,ptrCell%node3
      ENDDO

      READ(fileUnit,*)

   CALL closeFile(outputGMSHMeshFile)

   CALL nodeDBDestroy(vertices)
   CALL tria3DBDestroy(cells)

#endif

! ==================================================================================
! ==================================================================================
! Meshing procedure
! ==================================================================================
! ==================================================================================

!  Estimation of the number of cell and vertices
!  ==============================================

   nbOfVertices = 0
   nbOfCell = 0

   DO i1 = 1, nbOfContour
       ptrBoundaryLoop => contourDBGetValue(boundaryLoops,i1) ! take a pointer on the i1_th boundary loop in the data base
       CALL evaluateMeshSize(ptrBoundaryLoop,localNbOfVertices,localNbOfCell,meshCharacteristicLength)
       nbOfVertices = nbOfVertices + localNbOfVertices
       nbOfCell = nbOfCell + localNbOfCell
   ENDDO

   CALL nodeDBCreate(vertices,4,-3)
   CALL nodeDBAddSize(vertices,nbOfVertices)
   CALL nodeDBSetIncreaseSize(vertices,defaultIncrease)
   CALL tria3DBCreate(cells,2)
   CALL tria3DBAddSize(cells,nbOfCell)
   CALL tria3DBSetIncreaseSize(cells,defaultIncrease)


!  Insert new node on the boundaries if needed (distance between two nodes higher
!  than 2 * meshCharacteristicLength
!  ==================================================================================

print*,meshCharacteristicLength
  CALL insertNodesOnBoundary(boundaryLoops,meshCharacteristicLength)

!  Starting mesh
!  =============
   lengthX = getMaximumLongitude() - getMinimumLongitude()
   lengthY = getMaximumLatitude() - getMinimumLatitude()

   vertices%values(-3)%indexValue = -3
   vertices%values(-3)%xValue = getMinimumLongitude() - lengthX
   vertices%values(-3)%yValue = getMinimumLatitude() - lengthY

   vertices%values(-2)%indexValue = -2
   vertices%values(-2)%xValue = getMaximumLongitude() + lengthX
   vertices%values(-2)%yValue = getMinimumLatitude() - lengthY

   vertices%values(-1)%indexValue = -1
   vertices%values(-1)%xValue = getMaximumLongitude() + lengthX
   vertices%values(-1)%yValue = getMaximumLatitude() + lengthY

   vertices%values(0)%indexValue = 0
   vertices%values(0)%xValue = getMinimumLongitude() - lengthX
   vertices%values(0)%yValue = getMaximumLatitude() + lengthY

   cells%values(1)%indexValue = 1
   cells%values(1)%node1 = -3
   cells%values(1)%node2 = -2
   cells%values(1)%node3 = -1

   cells%values(1)%neighbor1 = 0
   cells%values(1)%neighbor2 = 0
   cells%values(1)%neighbor3 = 2

   cells%values(2)%indexValue = 1
   cells%values(2)%node1 = -1
   cells%values(2)%node2 = 0
   cells%values(2)%node3 = -3

   cells%values(2)%neighbor1 = 0
   cells%values(2)%neighbor2 = 0
   cells%values(2)%neighbor3 = 1

!  Introducing all boundary nodes
!  ==============================

   DO i1 = 1, nbOfContour
       ptrBoundaryLoop => contourDBGetValue(boundaryLoops,i1) ! take a pointer on the i1_th boundary loop in the data base
       CALL insertBoundaryNodesInMesh(vertices,cells,ptrBoundaryLoop)
   ENDDO


   CALL createFile(outputGMSHMeshFile,'diva.msh',formType=STD_FORMATTED)
   CALL exportToGMSH(outputGMSHMeshFile,vertices,cells)

   CALL contourDBDestroy(boundaryLoops)
   CALL nodeDBDestroy(vertices)
   CALL tria3DBDestroy(cells)
   CALL finaliseDIVAContext()

! ============================================================
! ============================================================
! ============================================================
! ===                                                      ===
! ===                                                      ===
! ===                  Program procedures                  ===
! ===                                                      ===
! ===                                                      ===
! ============================================================
! ============================================================
! ============================================================
 CONTAINS

! Procedure 2 : check if the new node is equal or not to previous one
! -------------------------------------------------------------------
FUNCTION  checkNewNode(ptrNode,newNode) RESULT(check)

!     Declaration
!     - - - - - -
      TYPE(node), POINTER :: ptrNode
      TYPE(node), INTENT(IN) :: newNode

      REAL(KIND=8), PARAMETER :: tolerance = 1.D-6
      REAL(KIND=8) :: xNew, yNew, xOld, yOld
      LOGICAL :: check

!     Body
!     - - -

      check = .TRUE.

      xOld = ptrNode%xValue
      yOld = ptrNode%yValue

      xNew = newNode%xValue
      yNew = newNode%yValue

      IF ( abs( xNew - xOld ) >= tolerance * abs( xNew + xOld ) ) THEN
         RETURN
      ENDIF

      IF ( abs( yNew - yOld ) >= tolerance * abs( yNew + yOld ) ) THEN
         RETURN
      ENDIF

!      PRINT*, 'Found two successive identical points ', ptrNode%indexValue

      check = .FALSE.

END FUNCTION

! Procedure 3 : export data to GMSH
! ---------------------------------
SUBROUTINE exportBoundaryToGMSH(outputGMSHFile,boundaryLoops,meshCharacteristicLength)

!     Declaration
!     - - - - - -
      TYPE(contourDataBase), INTENT(INOUT) :: boundaryLoops
      REAL(KIND=8), INTENT(IN) :: meshCharacteristicLength
      TYPE(file), INTENT(IN) :: outputGMSHFile

      INTEGER :: i1, nbOfContour, nbOfBoundarySegment, fileUnit
      TYPE(contour), POINTER :: ptrBoundaryLoop
      TYPE(lineDataBase), POINTER :: ptrLineDB

!     Body
!     - - -
      CALL openFile(outputGMSHFile)
      fileUnit = getFileUnit(outputGMSHFile)

      nbOfContour = contourDBGetSize(boundaryLoops)

!        Define characteristic length of each node
!        + + + + + + + + + + + + + + + + + + + + +
         DO i1 = 1, nbOfContour
            ptrBoundaryLoop => contourDBGetValue(boundaryLoops,i1)
            ptrLineDB => ptrBoundaryLoop%lineDB
            nbOfBoundarySegment = lineDBGetSize(ptrLineDB)
            ptrLineDB%values(1:nbOfBoundarySegment)%startNode%characteristicLength = meshCharacteristicLength
            ptrLineDB%values(1:nbOfBoundarySegment)%endNode%characteristicLength = meshCharacteristicLength
         ENDDO

!        Export nodes
!        + + + + + + +
         DO i1 = 1, nbOfContour
            ptrBoundaryLoop => contourDBGetValue(boundaryLoops,i1)
            ptrLineDB => ptrBoundaryLoop%lineDB
            CALL exportBoundaryLoopNodesToGMSH(fileUnit,ptrLineDB)
         ENDDO

!        Export boundary segments
!        + + + + + + + + + + + + +
         DO i1 = 1, nbOfContour
            ptrBoundaryLoop => contourDBGetValue(boundaryLoops,i1)
            ptrLineDB => ptrBoundaryLoop%lineDB
            CALL exportBoundaryLoopDataBaseToGMSH(fileUnit,ptrLineDB)
         ENDDO

!        Export boundary loop
!        + + + + + + + + + + +
         DO i1 = 1, nbOfContour
            ptrBoundaryLoop => contourDBGetValue(boundaryLoops,i1)
            CALL exportLoopToGMSH(fileUnit,ptrBoundaryLoop)
         ENDDO

!        Export contour
!        + + + + + + + +
         DO i1 = 1, nbOfContour
            ptrBoundaryLoop => contourDBGetValue(boundaryLoops,i1)
            CALL exportContourToGMSH(fileUnit,ptrBoundaryLoop)
         ENDDO

!        Export command
!        + + + + + + + +
         IF ( getGmshWithCoastRefinement() ) THEN
            CALL exportCommandToGMSHWithRefinement(fileUnit,boundaryLoops,meshCharacteristicLength)
         ELSE
            CALL exportCommandToGMSHWithoutRefinement(fileUnit,boundaryLoops,meshCharacteristicLength)
         ENDIF

      CALL closeFile(outputGMSHFile)

END SUBROUTINE

! Procedure 4 : export nodes to GMSH
! -----------------------------------
SUBROUTINE exportBoundaryLoopNodesToGMSH(fileUnit,ptrLineDB)

!     Declaration
!     - - - - - -
      TYPE(lineDataBase), POINTER :: ptrLineDB
      INTEGER, INTENT(IN) :: fileUnit
      INTEGER :: nbOfBoundarySegment, i1

!     Body
!     - - -
      nbOfBoundarySegment = lineDBGetSize(ptrLineDB)
      DO i1 = 1, nbOfBoundarySegment
           ptrLine => ptrLineDB%values(i1)
           CALL exportNodeToGMSH(fileUnit,ptrLine%startNode)
      ENDDO

END SUBROUTINE

! Procedure 5 : export boundary loop database to GMSH
! ----------------------------------------------------
SUBROUTINE exportBoundaryLoopDataBaseToGMSH(fileUnit,ptrLineDB)

!     Declaration
!     - - - - - -
      TYPE(lineDataBase), POINTER :: ptrLineDB
      INTEGER, INTENT(IN) :: fileUnit
      INTEGER :: nbOfBoundarySegment, i1

!     Body
!     - - -
      nbOfBoundarySegment = lineDBGetSize(ptrLineDB)
      DO i1 = 1, nbOfBoundarySegment
           ptrLine => ptrLineDB%values(i1)
           CALL exportBoundarySegmentToGMSH(fileUnit,ptrLine)
      ENDDO

END SUBROUTINE

! Procedure 6 : export boundary segment to GMSH
! ----------------------------------------------
SUBROUTINE exportBoundarySegmentToGMSH(fileUnit,ptrLine)

!     Declaration
!     - - - - - -
      TYPE(line), POINTER :: ptrLine
      INTEGER, INTENT(IN) :: fileUnit

!     Body
!     - - -
      WRITE(fileUnit,820) ptrLine%indexValue,ptrLine%startNode%indexValue,ptrLine%endNode%indexValue

820  FORMAT("Line(",i20,") = {",i20,",",i20,"};")

END SUBROUTINE

! Procedure 7 : export node to GMSH
! ----------------------------------
SUBROUTINE exportNodeToGMSH(fileUnit,nodeToExport)

!     Declaration
!     - - - - - -
      TYPE(node), INTENT(IN) :: nodeToExport
      INTEGER, INTENT(IN) :: fileUnit

!     Body
!     - - -
      WRITE(fileUnit,810) nodeToExport%indexValue,nodeToExport%xValue,nodeToExport%yValue,nodeToExport%zValue, &
                    nodeToExport%characteristicLength

810  FORMAT("Point(",i20,") = {", f20.10,",", f20.10,",", f20.10,",", f20.10,"};")

END SUBROUTINE

! Procedure 8 : export loop to GMSH
! ----------------------------------
SUBROUTINE exportLoopToGMSH(fileUnit,ptrBoundaryLoop)

!     Declaration
!     - - - - - -
      TYPE(contour), POINTER :: ptrBoundaryLoop
      TYPE(lineDataBase), POINTER :: ptrLineDB
      INTEGER, INTENT(IN) :: fileUnit
      INTEGER :: nbOfBoundarySegment, i1

!     Body
!     - - -
      ptrLineDB => ptrBoundaryLoop%lineDB
      nbOfBoundarySegment = lineDBGetSize(ptrLineDB)

      SELECT CASE (nbOfBoundarySegment)
         CASE (1)
            WRITE(fileUnit,860) ptrBoundaryLoop%indexValue,ptrLineDB%values(1)%indexValue
         CASE (2)
            WRITE(fileUnit,830) ptrBoundaryLoop%indexValue,ptrLineDB%values(1)%indexValue
            WRITE(fileUnit,850) ptrLineDB%values(nbOfBoundarySegment)%indexValue
         CASE DEFAULT
           WRITE(fileUnit,830) ptrBoundaryLoop%indexValue,ptrLineDB%values(1)%indexValue
           DO i1 = 2, nbOfBoundarySegment - 1
                WRITE(fileUnit,840) ptrLineDB%values(i1)%indexValue
           ENDDO
           WRITE(fileUnit,850) ptrLineDB%values(nbOfBoundarySegment)%indexValue
      END SELECT


830  FORMAT("Line Loop(",i20,") = {",i20,",")
840  FORMAT("                      ",i20,",")
850  FORMAT("                      ",i20,"};")
860  FORMAT("Line Loop(",i20,") = {",i20,"};")

END SUBROUTINE

! Procedure 9 : export contour to GMSH
! ----------------------------------
SUBROUTINE exportContourToGMSH(fileUnit,ptrBoundaryLoop)

!     Declaration
!     - - - - - -
      TYPE(contour), POINTER :: ptrBoundaryLoop
      TYPE(vectorInteger4), POINTER :: ptrInsideContour
      INTEGER, INTENT(IN) :: fileUnit
      INTEGER :: nbOfInsideContour, i1

!     Body
!     - - -
      IF ( .NOT.(ptrBoundaryLoop%meshFlag) ) THEN
         RETURN
      ENDIF

      ptrInsideContour => ptrBoundaryLoop%insideContour
      nbOfInsideContour = vectorGetSize(ptrInsideContour)

      SELECT CASE (nbOfInsideContour)
         CASE (0)
             WRITE(fileUnit,860) ptrBoundaryLoop%indexValue,ptrBoundaryLoop%indexValue
         CASE DEFAULT
             WRITE(fileUnit,830) ptrBoundaryLoop%indexValue,ptrBoundaryLoop%indexValue
             DO i1 = 1,nbOfInsideContour-1
                WRITE(fileUnit,840) ptrInsideContour%values(i1)
             ENDDO
             WRITE(fileUnit,850) ptrInsideContour%values(nbOfInsideContour)
      END SELECT

830  FORMAT("Plane Surface(",i20,") = {",i20,",")
840  FORMAT("                          ",i20,",")
850  FORMAT("                          ",i20,"};")
860  FORMAT("Plane Surface(",i20,") = {",i20,"};")

END SUBROUTINE


! Procedure 10 : search computational domain which has to be meshed
! -----------------------------------------------------------------
SUBROUTINE searchDomainToBeMeshed(boundaryLoops)

!     Declaration
!     - - - - - -
      TYPE(contourDataBase), INTENT(INOUT) :: boundaryLoops

      INTEGER :: i1, nbOfContour
!     Body
!     - - -
      nbOfContour = contourDBGetSize(boundaryLoops)

      DO i1 = 1, nbOfContour
         CALL searchInsideDomainOfBoundaryLoop(boundaryLoops,i1)
      ENDDO

      CALL flagDomainToBeMeshed(boundaryLoops)

END SUBROUTINE

! Procedure 11 : search inside domain in a specific boundary loop
! ---------------------------------------------------------------
SUBROUTINE searchInsideDomainOfBoundaryLoop(boundaryLoops,contourNumber)

!     Declaration
!     - - - - - -
      INTEGER, INTENT(IN) :: contourNumber
      TYPE(contourDataBase), INTENT(INOUT) :: boundaryLoops

      TYPE(contour), POINTER :: ptrBoundaryLoop, ptrBoundaryLoop1
      INTEGER :: i1, i2, nbOfContour

!     Body
!     - - -
      ptrBoundaryLoop => contourDBGetValue(boundaryLoops,contourNumber)

      nbOfContour = contourDBGetSize(boundaryLoops)

      i2 = 0
      DO i1 = 1, nbOfContour
         IF ( i1 /= contourNumber ) THEN
          ptrBoundaryLoop1 => contourDBGetValue(boundaryLoops,i1)
          IF ( checkIsInside(ptrBoundaryLoop,ptrBoundaryLoop1) ) THEN
             i2 = i2 + 1
             CALL vectorInsertValue(ptrBoundaryLoop%insideContour,i2,ptrBoundaryLoop1%indexValue)
          ENDIF
         ENDIF
      ENDDO

END SUBROUTINE

! Procedure 12 : check if the  boundary loop 1 is inside boundary loop
! --------------------------------------------------------------------
FUNCTION checkIsInside(ptrBoundaryLoop,ptrBoundaryLoop1) RESULT(check)

!     Declaration
!     - - - - - -
      TYPE(contour), POINTER :: ptrBoundaryLoop, ptrBoundaryLoop1

      TYPE(node), POINTER :: ptrNode1

      LOGICAL :: check, checkDomainLeftOrRight

      INTEGER :: nbOfBoundarySegment
      REAL(KIND=8) :: xValueNode1, yValueNode1, xValueNodeStart, yValueNodeStart, xValueNodeEnd, yValueNodeEnd
      REAL(KIND=8) :: distance, distanceBelow, distanceAbove, distanceRight, distanceLeft, slope, xIntersection, yIntersection
      TYPE(lineDataBase), POINTER :: ptrLineDB
      TYPE(line), POINTER :: lineBelow, lineAbove, lineRight, lineLeft, ptrLine

!     Body
!     - - -
      check = .TRUE.

      ptrNode1 => ptrBoundaryLoop1%lineDB%values(1)%startNode

      xValueNode1 = ptrNode1%xValue
      yValueNode1 = ptrNode1%yValue

      ptrLineDB => ptrBoundaryLoop%lineDB

      nbOfBoundarySegment = lineDBGetSize(ptrLineDB)

      distanceBelow = 1.D+9
      distanceAbove = 1.D+9
      distanceRight = 1.D+9
      distanceLeft = 1.D+9

      lineBelow => NULL()
      lineAbove => NULL()
      lineRight => NULL()
      lineLeft => NULL()

      DO i1 = 1, nbOfBoundarySegment
         ptrLine => ptrLineDB%values(i1)

         xValueNodeStart = ptrLine%startNode%xValue
         yValueNodeStart = ptrLine%startNode%yValue

         xValueNodeEnd = ptrLine%endNode%xValue
         yValueNodeEnd = ptrLine%endNode%yValue

         IF ( (xValueNodeStart <= xValueNode1).AND.(xValueNodeEnd >= xValueNode1) &
              .OR. &
              (xValueNodeStart >= xValueNode1).AND.(xValueNodeEnd <= xValueNode1) ) THEN

            slope = ( ( xValueNode1 - xValueNodeStart ) / ( xValueNodeEnd - xValueNodeStart ) )
            yIntersection = yValueNodeStart +  slope * ( yValueNodeEnd - yValueNodeStart )
            distance = abs(yIntersection - yValueNode1)

            IF ( yIntersection > yValueNode1 ) THEN
               IF ( distance < distanceAbove ) THEN
                   distanceAbove = distance
                   lineAbove => ptrLine
               ENDIF
            ELSE
               IF ( distance < distanceBelow ) THEN
                   distanceBelow = distance
                   lineBelow => ptrLine
               ENDIF
            ENDIF
            CYCLE
         ENDIF

         IF ( (yValueNodeStart <= yValueNode1).AND.(yValueNodeEnd >= yValueNode1) &
              .OR. &
              (yValueNodeStart >= yValueNode1).AND.(yValueNodeEnd <= yValueNode1) ) THEN

            slope = ( ( yValueNode1 - yValueNodeStart ) / ( yValueNodeEnd - yValueNodeStart ) )
            xIntersection = xValueNodeStart +  slope * ( xValueNodeEnd - xValueNodeStart )
            distance = abs(xIntersection - xValueNode1)

            IF ( xIntersection > xValueNode1 ) THEN
               IF ( distance < distanceRight ) THEN
                   distanceRight = distance
                   lineRight => ptrLine
               ENDIF
            ELSE
               IF ( distance < distanceLeft ) THEN
                   distanceLeft = distance
                   lineLeft => ptrLine
               ENDIF
            ENDIF
            CYCLE
         ENDIF

      ENDDO

      IF (.NOT.((associated(lineBelow)).AND.(associated(lineAbove)).AND.(associated(lineRight)).AND.(associated(lineLeft)))) THEN
         check = .FALSE.
         RETURN
      ENDIF

      CALL checkDomainPosition(ptrBoundaryLoop, checkDomainLeftOrRight)
                   ! if checkDomainLeftOrRight = true => the computational domain is on the left side of the boundary
                   !                           = false => the computational domain is on the rigth side of the boundary


      IF ( checkPosition(lineBelow,ptrNode1,checkDomainLeftOrRight) ) THEN
         check = .FALSE.
         RETURN
      ENDIF
      IF ( checkPosition(lineAbove,ptrNode1,checkDomainLeftOrRight) ) THEN
         check = .FALSE.
         RETURN
      ENDIF
      IF ( checkPosition(lineRight,ptrNode1,checkDomainLeftOrRight) ) THEN
         check = .FALSE.
         RETURN
      ENDIF
      IF ( checkPosition(lineLeft,ptrNode1,checkDomainLeftOrRight) ) THEN
         check = .FALSE.
         RETURN
      ENDIF

END FUNCTION

! Procedure 13 : check if the node is on the right side of the boundary
! ---------------------------------------------------------------------
FUNCTION checkPosition(ptrLine,ptrNode1,contourType) RESULT (check)

!     Declaration
!     - - - - - -
      TYPE(line), POINTER :: ptrLine
      TYPE(node), POINTER :: ptrNode1
      LOGICAL, INTENT(IN) :: contourType

      LOGICAL :: check
      REAL(KIND=8) :: xNodeStart, yNodeStart, xNodeEnd, yNodeEnd, vectorialProduct

!     Body
!     - - -
      check = .FALSE.

      xNodeStart = ptrLine%startNode%xValue
      yNodeStart = ptrLine%startNode%yValue
      xNodeEnd = ptrLine%endNode%xValue
      yNodeEnd = ptrLine%endNode%yValue

      vectorialProduct = (xNodeEnd - xNodeStart) * (ptrNode1%yValue - yNodeStart) - &
                         (yNodeEnd - yNodeStart) * (ptrNode1%xValue - xNodeStart)

      IF ( .NOT.(contourType) ) THEN
         vectorialProduct = (-1.) * vectorialProduct
      ENDIF

      IF ( vectorialProduct < 0. ) THEN
         check = .TRUE.
      ENDIF

END FUNCTION

! Procedure 14 : check if the computational domain is on the left side of the boundary or on the right side
! ---------------------------------------------------------------------------------------------------------
SUBROUTINE checkDomainPosition(ptrBoundaryLoop, check)

! Declaration
! -----------
     TYPE(contour), POINTER :: ptrBoundaryLoop

     LOGICAL, INTENT(OUT) :: check
     REAL(KIND=8) :: surface

! Body
! ----
    surface = contourComputeSurface(ptrBoundaryLoop)

    check = .FALSE.
    IF ( surface > 0. ) THEN
       check = .TRUE.
    ENDIF

END SUBROUTINE


! Procedure 15 : compute the distance between a boundary segment and a node
! -------------------------------------------------------------------------
FUNCTION computeDistance(xValueNodeStart,yValueNodeStart,xValueNodeEnd,yValueNodeEnd,xValueNode1,yValueNode1) RESULT(distance)

!     Declaration
!     - - - - - -
      REAL(KIND=8), INTENT(IN) :: xValueNodeStart,yValueNodeStart,xValueNodeEnd,yValueNodeEnd,xValueNode1,yValueNode1
      REAL(KIND=8) :: distance, xMiddle, yMiddle

!     Body
!     - - -

      xMiddle = 0.5 * (xValueNodeStart+xValueNodeEnd)
      yMiddle = 0.5 * (yValueNodeStart+yValueNodeEnd)
      distance = sqrt((xMiddle-xValueNode1)*(xMiddle-xValueNode1)+(yMiddle-yValueNode1)*(yMiddle-yValueNode1))

END FUNCTION

! Procedure 16 : flag to domain which has to be meshed
! ----------------------------------------------------
SUBROUTINE flagDomainToBeMeshed(boundaryLoops)

!     Declaration
!     - - - - - -
      TYPE(contourDataBase), INTENT(INOUT) :: boundaryLoops

      TYPE(contour), POINTER :: ptrBoundaryLoop
      TYPE(vectorInteger4), POINTER :: ptrInsideContour
      INTEGER(KIND=4), DIMENSION(:), POINTER :: ptrValues

      INTEGER :: i1, i2, nbOfContour, nbOfValues
      TYPE(vectorInteger4) :: storageVector
!     Body
!     - - -

      nbOfContour = contourDBGetSize(boundaryLoops)
      CALL vectorCreate(storageVector,nbOfContour)
      CALL vectorSetToZero(storageVector)

      DO i1 = 1, nbOfContour
          ptrBoundaryLoop => contourDBGetValue(boundaryLoops,i1)
          ptrInsideContour => ptrBoundaryLoop%insideContour
          ptrValues => vectorGetValues(ptrInsideContour)
          nbOfValues = vectorGetSize(ptrInsideContour)

          DO i2 = 1, nbOfValues
             CALL vectorFastAddValue(storageVector,ptrValues(i2),1)
          ENDDO
      ENDDO

      ptrValues => vectorGetValues(storageVector)
      ptrValues = modulo(ptrValues,2)

      DO i1 = 1, nbOfContour
          ptrBoundaryLoop => contourDBGetValue(boundaryLoops,i1)
          IF ( ptrValues(i1) == 0 ) THEN
             ptrBoundaryLoop%meshFlag = .TRUE.
          ELSE
             ptrBoundaryLoop%meshFlag = .FALSE.
          ENDIF
      ENDDO

      CALL vectorDestroy(storageVector)

END SUBROUTINE

! Procedure 17 : write command for meshing properties in gmsh
! -----------------------------------------------------------
SUBROUTINE exportCommandToGMSHWithoutRefinement(fileUnit,boundaryLoops,meshCharacteristicLength)

! Declaration
! -----------
     TYPE(contourDataBase), INTENT(IN) :: boundaryLoops
     REAL(KIND=8), INTENT(IN) :: meshCharacteristicLength
     INTEGER, INTENT(IN) :: fileUnit

     INTEGER :: i1 ,i2, nbOfContour, nbOfBoundarySegment
     TYPE(contour), POINTER :: ptrBoundaryLoop
     TYPE(lineDataBase), POINTER :: ptrLineDB


! Body
! ----
     WRITE(fileUnit,810)

     nbOfContour = contourDBGetSize(boundaryLoops)


     DO i1 = 1, nbOfContour
        ptrBoundaryLoop => contourDBGetValue(boundaryLoops,i1)
        ptrLineDB => ptrBoundaryLoop%lineDB
        nbOfBoundarySegment = lineDBGetSize(ptrLineDB)

        DO i2 = 1, nbOfBoundarySegment
          IF ( (i1 == 1).AND.(i2 ==1) ) THEN
             WRITE(fileUnit,830) ptrLineDB%values(i2)%indexValue
          ELSEIF ((i1 == nbOfContour).AND.(i2 ==nbOfBoundarySegment)) THEN
             WRITE(fileUnit,850) ptrLineDB%values(i2)%indexValue
          ELSE
             WRITE(fileUnit,840) ptrLineDB%values(i2)%indexValue
          ENDIF
        ENDDO
     ENDDO

     WRITE(fileUnit,820) meshCharacteristicLength
     WRITE(fileUnit,860) meshCharacteristicLength,meshCharacteristicLength
     WRITE(fileUnit,960) 2

810  FORMAT("Mesh.CharacteristicLengthExtendFromBoundary = 0;")
830  FORMAT("Field[1] = Attractor;",/,"Field[1].EdgesList = {",i20,",")
840  FORMAT("                      ",i20,",")
850  FORMAT("                      ",i20,"};")
820  FORMAT("Field[2] = Threshold;",/,"Field[2].DistMax = ",f20.10,";",/,"Field[2].DistMin = 0.;",/,"Field[2].IField = 1;")
860  FORMAT("Field[2].LcMax = ",f20.10,";",/,"Field[2].LcMin = ",f20.10,";",/,"Field[2].Sigmoid = 1;")

960  FORMAT("Background Field = ",i20,";")

END SUBROUTINE

! Procedure 18 : write command for meshing properties in gmsh
! -----------------------------------------------------------
SUBROUTINE exportCommandToGMSHWithRefinement(fileUnit,boundaryLoops,meshCharacteristicLength)

! Declaration
! -----------
     TYPE(contourDataBase), INTENT(IN) :: boundaryLoops
     REAL(KIND=8), INTENT(IN) :: meshCharacteristicLength
     INTEGER, INTENT(IN) :: fileUnit

     INTEGER :: i1 ,i2, i3,  nbOfContour, nbOfBoundarySegment, totalNbOfBoundarySegment, iLower, iHigher
     TYPE(contour), POINTER :: ptrBoundaryLoop
     TYPE(lineDataBase), POINTER :: ptrLineDB
     TYPE(line), POINTER :: ptrLine

     TYPE(vectorInteger4) :: attractorLengthLowerMeshCharacteristic, attractorLengthHigherMeshCharacteristic
     REAL(KIND=8) :: characteristicLength, xValueStart, yValueStart, xValueEnd, yValueEnd, length

! Body
! ----
     WRITE(fileUnit,810)

     nbOfContour = contourDBGetSize(boundaryLoops)

     totalNbOfBoundarySegment = 0

     DO i1 = 1, nbOfContour
        ptrBoundaryLoop => contourDBGetValue(boundaryLoops,i1)
        ptrLineDB => ptrBoundaryLoop%lineDB
        totalNbOfBoundarySegment = totalNbOfBoundarySegment + lineDBGetSize(ptrLineDB)
     ENDDO

     CALL vectorCreate(attractorLengthLowerMeshCharacteristic,totalNbOfBoundarySegment)
     CALL vectorCreate(attractorLengthHigherMeshCharacteristic,totalNbOfBoundarySegment)

     CALL vectorSetToZero(attractorLengthLowerMeshCharacteristic)
     CALL vectorSetToZero(attractorLengthHigherMeshCharacteristic)

     iLower = 0
     iHigher = 0
     characteristicLength = 0.

     DO i1 = 1, nbOfContour
        ptrBoundaryLoop => contourDBGetValue(boundaryLoops,i1)
        ptrLineDB => ptrBoundaryLoop%lineDB
        nbOfBoundarySegment = lineDBGetSize(ptrLineDB)

        DO i2 = 1, nbOfBoundarySegment
          ptrLine => ptrLineDB%values(i2)
          xValueStart = ptrLine%startNode%xValue
          yValueStart = ptrLine%startNode%yValue
          xValueEnd = ptrLine%endNode%xValue
          yValueEnd = ptrLine%endNode%yValue

          length = sqrt( (xValueStart-xValueEnd) * (xValueStart-xValueEnd)  + (yValueStart-yValueEnd) * (yValueStart-yValueEnd) )

          IF ( length < meshCharacteristicLength ) THEN
              iLower = iLower + 1
              CALL vectorFastInsertValue(attractorLengthLowerMeshCharacteristic,iLower,ptrLine%indexValue)
              characteristicLength = characteristicLength + length
          ELSE
              iHigher = iHigher + 1
              CALL vectorFastInsertValue(attractorLengthHigherMeshCharacteristic,iHigher,ptrLine%indexValue)
          ENDIF
        ENDDO

     ENDDO

     characteristicLength = characteristicLength / max(iLower,1)

     i2 = -1
     IF ( iLower > 0 ) THEN
        i2 = i2 + 2
        WRITE(fileUnit,830) i2, i2, attractorLengthLowerMeshCharacteristic%values(1)
        DO i1 = 2, iLower - 1
           WRITE(fileUnit,840) attractorLengthLowerMeshCharacteristic%values(i1)
        ENDDO
        WRITE(fileUnit,850) attractorLengthLowerMeshCharacteristic%values(iLower)

        i3 = i2 + 1
        WRITE(fileUnit,820) i3,i3,meshCharacteristicLength,i3,characteristicLength
        WRITE(fileUnit,821) i3,i2
        WRITE(fileUnit,860) i3,meshCharacteristicLength,i3,characteristicLength,i3
     ENDIF
     IF ( iHigher > 0 ) THEN
        i2 = i2 + 2
        WRITE(fileUnit,830) i2, i2, attractorLengthHigherMeshCharacteristic%values(1)
        DO i1 = 2, iHigher - 1
           WRITE(fileUnit,840) attractorLengthHigherMeshCharacteristic%values(i1)
        ENDDO
        WRITE(fileUnit,850) attractorLengthHigherMeshCharacteristic%values(iHigher)

        i3 = i2 + 1
        WRITE(fileUnit,820) i3,i3,meshCharacteristicLength,i3,meshCharacteristicLength
        WRITE(fileUnit,821) i3,i2
        WRITE(fileUnit,860) i3,meshCharacteristicLength,i3,meshCharacteristicLength,i3
     ENDIF

     SELECT CASE (i2)
        CASE (1)
           WRITE(fileUnit,960) 2
        CASE (3)
           WRITE(fileUnit,910) 5
           WRITE(fileUnit,920) 5,2,4
           WRITE(fileUnit,960) 5
     END SELECT

     CALL vectorDestroy(attractorLengthLowerMeshCharacteristic)
     CALL vectorDestroy(attractorLengthHigherMeshCharacteristic)

810  FORMAT("Mesh.CharacteristicLengthExtendFromBoundary = 0;")
830  FORMAT("Field[",i20,"] = Attractor;",/,"Field[",i20,"].EdgesList = {",i20,",")
840  FORMAT("                      ",i20,",")
850  FORMAT("                      ",i20,"};")
820  FORMAT("Field[",i20,"] = Threshold;",/,"Field[",i20,"].DistMax = ",f20.10,";",/,"Field[",i20,"].DistMin = ",f20.10,";")
821  FORMAT("Field[",i20,"].IField = ",i20,";")
860  FORMAT("Field[",i20,"].LcMax = ",f20.10,";",/,"Field[",i20,"].LcMin = ",f20.10,";",/,"Field[",i20,"].Sigmoid = 1;")

910  FORMAT("Field[",i20,"] = Min ;")
920  FORMAT("Field[",i20,"].FieldsList = {",i20,",",i20,"};")
960  FORMAT("Background Field = ",i20,";")

END SUBROUTINE

! Procedure 19 : run gmsh
! -----------------------
SUBROUTINE runGMSH(outputGMSHFile,outputGMSHMeshFile)

! Declaration
! -----------
     TYPE(file), INTENT(IN) :: outputGMSHFile, outputGMSHMeshFile
     CHARACTER(LEN=301) :: command

! Body
! ----
     command = 'gmsh -2 -smooth 10 -algo meshadapt ' // outputGMSHFile%fileName &
               // ' -o ' // outputGMSHMeshFile%fileName
     print*,command
     CALL system(command)
     print*,command

END SUBROUTINE

! Procedure 20 : change coordinate
! --------------------------------
SUBROUTINE changeLongLatToXY(ptrBoundaryLoopSegment)

!     Declaration
!     - - - - - -
      TYPE(lineDataBase), POINTER :: ptrBoundaryLoopSegment

      INTEGER :: i1, nbOfData
      REAL(KIND=8), POINTER :: xValue, yValue
      REAL(KIND=8) :: deltaXInKm, deltaYInKm, meanLongitude, meanLatitude, deltaY, pi

!     Body
!     - - -
      meanLongitude = getMeanLongitude()
      nbOfData = lineDBGetSize(ptrBoundaryLoopSegment)

      SELECT CASE (getISpheric())
         CASE (1)
            pi = getPi() / 180.
            deltaY = 0.001 * ( getMaximumLatitude() - getMinimumLatitude() )

            DO i1 = 1, nbOfData
               ptrLine => ptrBoundaryLoopSegment%values(i1)
               xValue =>  ptrLine%startNode%xValue
               yValue =>  ptrLine%startNode%yValue
               xValue = ( xValue - meanLongitude ) * max(cos(yValue*pi),cos(90.*pi-deltaY*pi))

               xValue =>  ptrLine%endNode%xValue
               yValue =>  ptrLine%endNode%yValue
               xValue = ( xValue - meanLongitude ) * max(cos(yValue*pi),cos(90.*pi-deltaY*pi))
            ENDDO

         CASE DEFAULT
            deltaXInKm = getDeltaXInKm()
            deltaYInKm = getDeltaYInKm()

            meanLatitude = getMeanLatitude()

            DO i1 = 1, nbOfData
               ptrLine => ptrBoundaryLoopSegment%values(i1)
               xValue =>  ptrLine%startNode%xValue
               yValue =>  ptrLine%startNode%yValue
               xValue = ( xValue - meanLongitude ) * deltaXInKm
               yValue = ( yValue - meanLatitude ) * deltaYInKm

               xValue =>  ptrLine%endNode%xValue
               yValue =>  ptrLine%endNode%yValue
               xValue = ( xValue - meanLongitude ) * deltaXInKm
               yValue = ( yValue - meanLatitude ) * deltaYInKm
            ENDDO


      END SELECT

END SUBROUTINE

! Procedure 21 : compute mean value of latitude and longitude
! -----------------------------------------------------------
SUBROUTINE computeMeanCoordinate(boundaryLoops)

!     Declaration
!     - - - - - -
      TYPE(contourDataBase), INTENT(INOUT) :: boundaryLoops
      TYPE(contour), POINTER :: ptrBoundaryLoop

      TYPE(lineDataBase), POINTER :: ptrLineDB

      INTEGER :: i1, nbOfContour, nbOfNode, nbOfBoundarySegment
      REAL(KIND=8) :: meanX, meanY

!     Body
!     - - -
      meanX = 0.
      meanY = 0.
      nbOfNode = 0

      nbOfContour = contourDBGetSize(boundaryLoops)

      DO i1 = 1, nbOfContour
         ptrBoundaryLoop => contourDBGetValue(boundaryLoops,i1)
         ptrLineDB => ptrBoundaryLoop%lineDB
         nbOfBoundarySegment = lineDBGetSize(ptrLineDB)
         nbOfNode = nbOfNode + nbOfBoundarySegment
         meanX = meanX + sum(ptrLineDB%values(1:nbOfBoundarySegment)%startNode%xValue)
         meanY = meanY + sum(ptrLineDB%values(1:nbOfBoundarySegment)%startNode%yValue)
      ENDDO

      meanX = meanX / max(nbOfNode,1)
      meanY = meanY / max(nbOfNode,1)

      CALL setMeanXCoordinate(meanX)
      CALL setMeanYCoordinate(meanY)

END SUBROUTINE

! Procedure 22 : shift all coordinate with respect to meanX and meanY
! -------------------------------------------------------------------
SUBROUTINE shiftAllCoordinate(boundaryLoops)

!     Declaration
!     - - - - - -
      TYPE(contourDataBase), INTENT(INOUT) :: boundaryLoops
      TYPE(contour), POINTER :: ptrBoundaryLoop

      TYPE(lineDataBase), POINTER :: ptrLineDB
      TYPE(line), DIMENSION(:), POINTER :: ptrLines

      INTEGER :: i1, nbOfContour, nbOfBoundarySegment
      REAL(KIND=8) :: meanX, meanY, characteristicLength

!     Body
!     - - -
      meanX = getMeanXCoordinate()
      meanY = getMeanYCoordinate()
      characteristicLength = getDimensionLessLength()

      nbOfContour = contourDBGetSize(boundaryLoops)

      DO i1 = 1, nbOfContour
         ptrBoundaryLoop => contourDBGetValue(boundaryLoops,i1)
         ptrLineDB => ptrBoundaryLoop%lineDB
         nbOfBoundarySegment = lineDBGetSize(ptrLineDB)
         ptrLines => lineDBGetValues(ptrLineDB)
         ptrLines(1:nbOfBoundarySegment)%startNode%xValue = ( ptrLines(1:nbOfBoundarySegment)%startNode%xValue - meanX ) / &
                                                            characteristicLength
         ptrLines(1:nbOfBoundarySegment)%startNode%yValue = ( ptrLines(1:nbOfBoundarySegment)%startNode%yValue - meanY ) / &
                                                            characteristicLength
         ptrLines(1:nbOfBoundarySegment)%endNode%xValue = ( ptrLines(1:nbOfBoundarySegment)%endNode%xValue - meanX ) / &
                                                          characteristicLength
         ptrLines(1:nbOfBoundarySegment)%endNode%yValue = ( ptrLines(1:nbOfBoundarySegment)%endNode%yValue - meanY ) / &
                                                          characteristicLength
      ENDDO

END SUBROUTINE

! Procedue 23 : insert new nodes on the boundaries
! ------------------------------------------------
SUBROUTINE insertNodesOnBoundary(boundaryLoops,meshCharacteristicLength)

!     Declaration
!     - - - - - -
      REAL(KIND=8), INTENT(IN) :: meshCharacteristicLength
      TYPE(contourDataBase), INTENT(INOUT) :: boundaryLoops
      TYPE(contour), POINTER :: ptrBoundaryLoop

      TYPE(lineDataBase), POINTER :: ptrLineDB
      TYPE(line), POINTER :: ptrSpecificLine

      INTEGER :: i1, nbOfContour, nbOfBoundarySegment, lastNodeIndex

!     Body
!     - - -

      nbOfContour = contourDBGetSize(boundaryLoops)
      ptrBoundaryLoop => contourDBGetValue(boundaryLoops,nbOfContour)
      ptrLineDB => ptrBoundaryLoop%lineDB
      nbOfBoundarySegment = lineDBGetSize(ptrLineDB)
      ptrSpecificLine => lineDBGetValue(ptrLineDB,nbOfBoundarySegment)
      lastNodeIndex = ptrSpecificLine%startNode%indexValue

      DO i1 = 1, nbOfContour
         ptrBoundaryLoop => contourDBGetValue(boundaryLoops,i1)
         CALL insertNodesOnSpecificBoundary(ptrBoundaryLoop,meshCharacteristicLength,lastNodeIndex)
      ENDDO

END SUBROUTINE

! Procedure 24 : insert new nodes on a specific boundary
! ------------------------------------------------------
SUBROUTINE insertNodesOnSpecificBoundary(ptrBoundaryLoop,meshCharacteristicLength,lastNodeIndex)

!     Declaration
!     - - - - - -
      REAL(KIND=8), INTENT(IN) :: meshCharacteristicLength
      INTEGER, INTENT(INOUT) :: lastNodeIndex
      TYPE(contour), POINTER :: ptrBoundaryLoop

      TYPE(lineDataBase), POINTER :: ptrLineDB
      TYPE(line), POINTER :: ptrSpecificLine
      TYPE(line) :: lineElement

      INTEGER :: i1, nbOfBoundarySegment, tooFineCounter, lineIndex, nbOfAddedNode, nbOfAddedNode1
      REAL(KIND=8) :: length, xStart, yStart, xEnd, yEnd, lambda

      TYPE(vectorInteger4) :: checkingVector
      INTEGER(KIND=4), DIMENSION(:), POINTER :: ptrCheckingVector
      TYPE(node) :: endLineNode = node(0.,0.,0.,0,0.), nodeElement = node(0.,0.,0.,0,0.)

!     Body
!     - - -
      ptrLineDB => ptrBoundaryLoop%lineDB
      nbOfBoundarySegment = lineDBGetSize(ptrLineDB)

      tooFineCounter = 0
      lineIndex = nbOfBoundarySegment

      CALL vectorCreate(checkingVector,nbOfBoundarySegment)
      CALL vectorSetToZero(checkingVector)

!     1) Check if the boundary segment has to be refined
!     ++++++++++++++++++++++++++++++++++++++++++++++++++

      DO i1 = 1, nbOfBoundarySegment

         ptrSpecificLine => lineDBGetValue(ptrLineDB,i1)
         length = lineComputeLength(ptrSpecificLine)

         IF ( length < 0.5 * meshCharacteristicLength ) THEN
            tooFineCounter = tooFineCounter + 1
            CYCLE
         ENDIF

         CALL vectorFastInsertValue(checkingVector,i1,INT(length/meshCharacteristicLength))

      ENDDO

      IF ( tooFineCounter > 0 ) THEN
        PRINT*, 'Warning, contour is too fine for ', tooFineCounter, ' segments. '
      ENDIF

!     2) Insert nodes on too long boundary segment
!     ++++++++++++++++++++++++++++++++++++++++++++
      ptrCheckingVector => vectorGetValues(checkingVector)

      DO i1 = 1, nbOfBoundarySegment

         IF ( ptrCheckingVector(i1) <= 0 ) THEN
            CYCLE
         ENDIF

         ptrSpecificLine => lineDBGetValue(ptrLineDB,i1)

         xStart = ptrSpecificLine%startNode%xValue
         yStart = ptrSpecificLine%startNode%yValue

         endLineNode = ptrSpecificLine%endNode
         xEnd = ptrSpecificLine%endNode%xValue
         yEnd = ptrSpecificLine%endNode%yValue

         length = lineComputeLength(ptrSpecificLine)

         nbOfAddedNode = ptrCheckingVector(i1) - 1
         nbOfAddedNode1 = nbOfAddedNode + 1

         CALL lineDBSetIncreaseSize(ptrLineDB,nbOfAddedNode)

         lastNodeIndex = lastNodeIndex + 1
         nodeElement%indexValue = lastNodeIndex
         lambda = REAL(1,KIND=8) / REAL(nbOfAddedNode1,KIND=8)
         nodeElement%xValue = xStart + lambda * ( xEnd - xStart )
         nodeElement%yValue = yStart + lambda * ( yEnd - yStart )

         ptrSpecificLine%endNode = nodeElement

         DO i2 = 2, nbOfAddedNode

            lineIndex = lineIndex + 1
            lineElement%indexValue = lineIndex
            lineElement%startNode = nodeElement

            lastNodeIndex = lastNodeIndex + 1
            nodeElement%indexValue = lastNodeIndex
            lambda = REAL(i2,KIND=8) / REAL(nbOfAddedNode1,KIND=8)
            nodeElement%xValue = xStart + lambda * ( xEnd - xStart )
            nodeElement%yValue = yStart + lambda * ( yEnd - yStart )

            lineElement%endNode = nodeElement

            CALL lineDBPushBack(ptrLineDB,lineElement)

         ENDDO

         lineIndex = lineIndex + 1
         lineElement%indexValue = lineIndex
         lineElement%startNode = nodeElement
         lineElement%endNode = endLineNode

         CALL lineDBPushBack(ptrLineDB,lineElement)

      ENDDO

END SUBROUTINE

! Procedure 25 : estimation of mesh size
! --------------------------------------
SUBROUTINE evaluateMeshSize(ptrBoundaryLoop,nbOfVertices,nbOfCell,meshCharacteristicLength)

!     Declaration
!     - - - - - -
      REAL(KIND=8), INTENT(IN) :: meshCharacteristicLength
      INTEGER, INTENT(INOUT) :: nbOfVertices, nbOfCell
      TYPE(contour), POINTER :: ptrBoundaryLoop

      REAL(KIND=8) :: surface, length
      INTEGER :: refValue

!     Body
!     - - -
      surface = abs(contourComputeSurface(ptrBoundaryLoop))
      length = sqrt(surface)

      refValue = INT(length / meshCharacteristicLength)
      nbOfVertices = ( refValue + 1 ) * ( refValue + 1 )
      nbOfCell = 2 * refValue * refValue

END SUBROUTINE

! Procedure 26 : export mesh to gmsh for vizualisation
! ----------------------------------------------------
SUBROUTINE exportToGMSH(fileToWrite,vertices,cells)

!     Declaration
!     - - - - - -
      TYPE(nodeDataBase), INTENT(IN) :: vertices
      TYPE(tria3DataBase),INTENT(IN) :: cells
      TYPE(file), INTENT(IN) :: fileToWrite

      INTEGER :: fileUnit, nbOfVertices, iStartValue, iEndValue, nbOfCell
      TYPE(node), DIMENSION(:), POINTER :: ptrNodeValue
      TYPE(node), POINTER :: ptrNode

      TYPE(tria3), DIMENSION(:), POINTER :: ptrCellValue
      TYPE(tria3), POINTER :: ptrCell

!     Body
!     - - -
     CALL openFile(fileToWrite)
     fileUnit = getFileUnit(fileToWrite)

     WRITE(fileUnit,810)

!    1) write information
!    - - - - - - - - - - -
!       1.1) nodes
!       + + + + + +
     nbOfVertices = nodeDBGetSize(vertices)
     iStartValue = nodeDBGetFirstIndex(vertices)
     iEndValue = nodeDBGetLastIndex(vertices)
     ptrNodeValue => nodeDBGetValues(vertices)

     WRITE(fileUnit,820)
     WRITE(fileUnit,*) nbOfVertices
     DO i1 = iStartValue, iEndValue
        ptrNode => ptrNodeValue(i1)
        WRITE(fileUnit,*) ptrNode%indexValue, ptrNode%xValue, ptrNode%yValue, ptrNode%zValue
     ENDDO
     WRITE(fileUnit,830)

!       1.2) cell topology
!       + + + + + + + + + +
     nbOfCell = tria3DBGetSize(cells)
     iStartValue = tria3DBGetFirstIndex(cells)
     iEndValue = tria3DBGetLastIndex(cells)
     ptrCellValue => tria3DBGetValues(cells)

     WRITE(fileUnit,840)
     WRITE(fileUnit,*) nbOfCell
     DO i1 = 1, nbOfCell
        ptrCell => ptrCellValue(i1)
        WRITE(fileUnit,*) ptrCell%indexValue,2,2,99,2,ptrCell%node1, ptrCell%node2, ptrCell%node3
     ENDDO
     WRITE(fileUnit,850)

     CALL closeFile(fileToWrite)

810  FORMAT("$MeshFormat",/,"2.1 0 8",/,"$EndMeshFormat")
820  FORMAT("$Nodes")
830  FORMAT("$EndNodes")
840  FORMAT("$Elements")
850  FORMAT("$EndElements")

END SUBROUTINE

! Procedure 27 : inserting boundary nodes in the mesh
! ---------------------------------------------------
SUBROUTINE insertBoundaryNodesInMesh(vertices,cells,ptrBoundaryLoop)

!     Declaration
!     - - - - - -
      TYPE(nodeDataBase), INTENT(IN) :: vertices
      TYPE(tria3DataBase),INTENT(IN) :: cells
      TYPE(contour), POINTER :: ptrBoundaryLoop

      INTEGER :: nbOfBoundaryNode
      TYPE(lineDataBase), POINTER :: ptrLineDB
      TYPE(node), POINTER :: ptrNode

!     Body
!     - - -

      ptrLineDB => ptrBoundaryLoop%lineDB
      nbOfBoundaryNode = lineDBGetSize(ptrLineDB)

      DO i1 = 1, nbOfBoundaryNode
         ptrNode => ptrLineDB%values(i1)%startNode
         CALL insertNodeInMesh(vertices,cells,ptrNode)
      ENDDO

END SUBROUTINE

! Procedure 28 : insert a node in the mesh
! ----------------------------------------
SUBROUTINE insertNodeInMesh(vertices,cells,ptrNode,motherCellNumber)

!     Declaration
!     - - - - - -
      TYPE(nodeDataBase), INTENT(IN) :: vertices
      TYPE(tria3DataBase),INTENT(IN) :: cells
      TYPE(node), POINTER :: ptrNode

      TYPE(tria3), OPTIONAL, POINTER :: motherCellNumber
      TYPE(tria3), POINTER :: ptrCell

      INTEGER, PARAMETER :: defautlSize = 20
      TYPE(vectorInteger4) :: affectedCell, affectedCellCheck, finalAffectedCell
      INTEGER(KIND=4), DIMENSION(:), POINTER :: ptrAffectedCellValue, ptrAffectedCellCheckValue, ptrFinalAffectedCellValue
      INTEGER :: iCheck, iTotalCheck, n1, nbOfAffectedCell, nbOfVertice, i1, i2

      TYPE(tria3DataBase) :: localMesh
      TYPE(tria3), DIMENSION(:), POINTER :: ptrLocalMesh
      TYPE(tria3) :: localCell = tria3(0,0,0,0,0,0,0)

!     Body
!     - - -

!     1) Search cell containing the node
!     ++++++++++++++++++++++++++++++++++
      IF ( PRESENT(motherCellNumber) ) THEN
         ptrCell => motherCellNumber
      ELSE
         ptrCell => searchInitialCell(vertices,cells,ptrNode)
      ENDIF

!     2) Search complete affected stencil (delaunay criterion)
!     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++

      CALL vectorCreate(affectedCell,defautlSize)
      CALL vectorSetIncreaseSize(affectedCell,defautlSize)
      CALL vectorCreate(affectedCellCheck,defautlSize)
      CALL vectorSetIncreaseSize(affectedCellCheck,defautlSize)

      ptrAffectedCellValue => affectedCell%values

      CALL vectorFastInsertValue(affectedCell,1,ptrCell%indexValue)
      CALL vectorFastInsertValue(affectedCellCheck,1,1)
      iTotalCheck = 1
      n1 = ptrCell%neighbor1
      IF ( n1 > 0 ) THEN
         iTotalCheck = iTotalCheck + 1
         CALL vectorInsertValue(affectedCell,iTotalCheck,n1)
         CALL vectorInsertValue(affectedCellCheck,iTotalCheck,0)
      ENDIF
      n1 = ptrCell%neighbor2
      IF ( n1 > 0 ) THEN
         iTotalCheck = iTotalCheck + 1
         CALL vectorInsertValue(affectedCell,iTotalCheck,n1)
         CALL vectorInsertValue(affectedCellCheck,iTotalCheck,0)
      ENDIF
      n1 = ptrCell%neighbor3
      IF ( n1 > 0 ) THEN
         iTotalCheck = iTotalCheck + 1
         CALL vectorInsertValue(affectedCell,iTotalCheck,n1)
         CALL vectorInsertValue(affectedCellCheck,iTotalCheck,0)
      ENDIF

      iCheck = 2

      DO WHILE ( iCheck <= iTotalCheck )

           ptrCell => tria3DBGetValue(cells,ptrAffectedCellValue(iCheck))
           IF ( delaunayCriterion(ptrNode,ptrCell,vertices) ) THEN

              n1 = ptrCell%neighbor1
              IF ( n1 > 0 ) THEN
                 IF ( .NOT.(vectorIsAlreadyIn(affectedCell,n1) )) THEN
                    iTotalCheck = iTotalCheck + 1
                    CALL vectorInsertValue(affectedCell,iTotalCheck,n1)
                    CALL vectorInsertValue(affectedCellCheck,iTotalCheck,0)
                 ENDIF
              ENDIF

              n1 = ptrCell%neighbor2
              IF ( n1 > 0 ) THEN
                 IF ( .NOT.(vectorIsAlreadyIn(affectedCell,n1) )) THEN
                    iTotalCheck = iTotalCheck + 1
                    CALL vectorInsertValue(affectedCell,iTotalCheck,n1)
                    CALL vectorInsertValue(affectedCellCheck,iTotalCheck,0)
                 ENDIF
              ENDIF

              n1 = ptrCell%neighbor3
              IF ( n1 > 0 ) THEN
                 IF ( .NOT.(vectorIsAlreadyIn(affectedCell,n1) )) THEN
                    iTotalCheck = iTotalCheck + 1
                    CALL vectorInsertValue(affectedCell,iTotalCheck,n1)
                    CALL vectorInsertValue(affectedCellCheck,iTotalCheck,0)
                 ENDIF
              ENDIF

              CALL vectorInsertValue(affectedCellCheck,iCheck,1)
           ELSE
              CALL vectorInsertValue(affectedCellCheck,iCheck,0)
           ENDIF

           iCheck = iCheck + 1
      END DO

      nbOfAffectedCell = vectorSum(affectedCellCheck)
      ptrAffectedCellCheckValue => vectorGetValues(affectedCellCheck)

      CALL vectorCreate(finalAffectedCell,nbOfAffectedCell)
      ptrFinalAffectedCellValue => vectorGetValues(finalAffectedCell)

      i2 = 0
      DO i1 = 1, iTotalCheck
         IF ( ptrAffectedCellCheckValue(i1) == 1 ) THEN
            i2 = i2 + 1
            ptrFinalAffectedCellValue(i2) = ptrAffectedCellValue(i1)
         ENDIF
      ENDDO

      CALL vectorDestroy(affectedCell)
      CALL vectorDestroy(affectedCellCheck)

!     3) Insert the new node in the database
!     ++++++++++++++++++++++++++++++++++++++
      nbOfVertice = nodeDBGetLastIndex(vertices)
      CALL nodeDBInsert(vertices,nbOfVertice+1,ptrNode)

!     4) organize the stencil to be modified
!     ++++++++++++++++++++++++++++++++++++++

      CALL tria3DBCreate(localMesh,2*nbOfAffectedCell)
      ptrLocalMesh => tria3DBGetValues(localMesh)

      i2 = 0
      DO i1 = 1, nbOfAffectedCell
          ptrCell => tria3DBGetValue(cells,ptrFinalAffectedCellValue(i1))
          n1 = ptrCell%neighbor1
          IF ( .NOT.(vectorIsAlreadyIn(finalAffectedCell,n1))) THEN
             i2 = i2 + 1
             localCell%indexValue = i2
             localCell%node1 = ptrCell%node1
             localCell%node2 = ptrCell%node2
             localCell%node3 = ptrNode%indexValue
             localCell%neighbor1 = n1
             ptrLocalMesh(i2) = localCell
          ENDIF
          n1 = ptrCell%neighbor2
          IF ( .NOT.(vectorIsAlreadyIn(finalAffectedCell,n1) )) THEN
             i2 = i2 + 1
             localCell%indexValue = i2
             localCell%node1 = ptrCell%node2
             localCell%node2 = ptrCell%node3
             localCell%node3 = ptrNode%indexValue
             localCell%neighbor1 = ptrCell%neighbor2
             ptrLocalMesh(i2) = localCell
          ENDIF
          n1 = ptrCell%neighbor3
          IF ( .NOT.(vectorIsAlreadyIn(finalAffectedCell,n1) )) THEN
             i2 = i2 + 1
             localCell%indexValue = i2
             localCell%node1 = ptrCell%node3
             localCell%node2 = ptrCell%node1
             localCell%node3 = ptrNode%indexValue
             localCell%neighbor1 = ptrCell%neighbor3
             ptrLocalMesh(i2) = localCell
          ENDIF

      ENDDO

      call tria3DBPrint(localMesh)
      stop


!      nbOfLocalCell = i2
!      nbOfnewCell = nbOfLocalCell - nbOfAffectedCell
!
!      DO i1 = 1, nbOfLocalCell
!         ptrLocalCell => ptrLocalMesh%values(i1)
!         no1 = ptrLocalCell%node1
!         no2 = ptrLocalCell%node2
!         no3 = ptrLocalCell%node3
!
!         DO i2 = 1, nbOfLocalCell
!            ptrLocalCell2 => ptrLocalMesh%values(i2)
!            no1b = ptrLocalCell2%node1
!            no2b = ptrLocalCell2%node2
!            no3b = ptrLocalCell2%node3
!
!            IF (
!
!         ENDDO
!      ENDDO

      CALL tria3DBDestroy(localMesh)
END SUBROUTINE

! Procedure 29 : search cell in which the node is located
! -------------------------------------------------------
FUNCTION searchInitialCell(vertices,cells,ptrNode) RESULT(ptrCell)

!     Declaration
!     - - - - - -
      TYPE(nodeDataBase), INTENT(IN) :: vertices
      TYPE(tria3DataBase),INTENT(IN) :: cells
      TYPE(node), POINTER :: ptrNode

      INTEGER :: neighborConcerned, neighbor
      TYPE(tria3), DIMENSION(:), POINTER :: ptrCellDB
      TYPE(node), DIMENSION(:), POINTER :: ptrVerticesDB
      TYPE(tria3), POINTER :: ptrCell
      LOGICAL :: repositionning
      REAL(KIND=8) :: lambda
      TYPE(node), POINTER :: ptrNode1, ptrNode2

!     Body
!     - - -
      ptrCellDB => tria3DBGetValues(cells)
      ptrVerticesDB => nodeDBGetValues(vertices)

      ptrCell => ptrCellDB(1)

10    CONTINUE

      repositionning = .FALSE.

      IF ( .NOT.(vectorialProduct(ptrNode,ptrVerticesDB(ptrCell%node1),ptrVerticesDB(ptrCell%node2))) ) THEN
         neighbor = ptrCell%neighbor1
         IF ( neighbor <= 0 ) THEN
            repositionning = .TRUE.
            neighborConcerned = 1
            GOTO 20
         ENDIF
         ptrCell => ptrCellDB(neighbor)
         GOTO 10
      ENDIF

20    CONTINUE

      IF ( .NOT.(vectorialProduct(ptrNode,ptrVerticesDB(ptrCell%node2),ptrVerticesDB(ptrCell%node3))) ) THEN
         neighbor = ptrCell%neighbor2
         IF ( neighbor <= 0 ) THEN
            repositionning = .TRUE.
            neighborConcerned = 2
            GOTO 30
         ENDIF
         ptrCell => ptrCellDB(neighbor)
         GOTO 10
      ENDIF

30    CONTINUE

      IF ( .NOT.(vectorialProduct(ptrNode,ptrVerticesDB(ptrCell%node3),ptrVerticesDB(ptrCell%node1))) ) THEN
         neighbor = ptrCell%neighbor3
         IF ( neighbor <= 0 ) THEN
            repositionning = .TRUE.
            neighborConcerned = 3
            GOTO 40
         ENDIF
         ptrCell => ptrCellDB(neighbor)
         GOTO 10
      ENDIF
40    CONTINUE

      IF ( repositionning ) THEN

         SELECT CASE ( neighborConcerned )
            CASE (1)
                ptrNode1 => ptrVerticesDB(ptrCell%node1)
                ptrNode2 => ptrVerticesDB(ptrCell%node2)
                lambda = scalarProduct(ptrNode,ptrNode1,ptrNode2)
                ptrNode%xValue = ptrNode1%xValue + lambda * ( ptrNode2%xValue - ptrNode1%xValue )
                ptrNode%yValue = ptrNode1%yValue + lambda * ( ptrNode2%yValue - ptrNode1%yValue )
            CASE (2)
                ptrNode1 => ptrVerticesDB(ptrCell%node2)
                ptrNode2 => ptrVerticesDB(ptrCell%node3)
                lambda = scalarProduct(ptrNode,ptrNode1,ptrNode2)
                ptrNode%xValue = ptrNode1%xValue + lambda * ( ptrNode2%xValue - ptrNode1%xValue )
                ptrNode%yValue = ptrNode1%yValue + lambda * ( ptrNode2%yValue - ptrNode1%yValue )
            CASE (3)
                ptrNode1 => ptrVerticesDB(ptrCell%node3)
                ptrNode2 => ptrVerticesDB(ptrCell%node1)
                lambda = scalarProduct(ptrNode,ptrNode1,ptrNode2)
                ptrNode%xValue = ptrNode1%xValue + lambda * ( ptrNode2%xValue - ptrNode1%xValue )
                ptrNode%yValue = ptrNode1%yValue + lambda * ( ptrNode2%yValue - ptrNode1%yValue )
         END SELECT
      ENDIF

END FUNCTION

! Procedure 30 : compute vectorial product
! ----------------------------------------
FUNCTION vectorialProduct(ptrNodeCheck, ptrNodeStart, ptrNodeEnd) RESULT(check)

!     Declaration
!     - - - - - -
      TYPE(node), POINTER :: ptrNodeCheck
      TYPE(node), INTENT(IN) ::  ptrNodeStart, ptrNodeEnd
      LOGICAL :: check

      REAL(KIND=8), DIMENSION(2) :: a, b
      REAL(KIND=8) :: pVectoriel
      REAL(KIND=8), PARAMETER :: tolerance = -1.D-8

!     Body
!     - - -

      a(1) = ptrNodeEnd%xValue - ptrNodeStart%xValue
      a(2) = ptrNodeEnd%yValue - ptrNodeStart%yValue
      b(1) = ptrNodeCheck%xValue - ptrNodeStart%xValue
      b(2) = ptrNodeCheck%yValue - ptrNodeStart%yValue

      pVectoriel = a(1) * b(2) - a(2) * b(1)

      check = .TRUE.

      IF ( pVectoriel < tolerance ) THEN
         check = .FALSE.
      ENDIF

END FUNCTION

! Procedure 31 : compute scalar product
! ----------------------------------------
FUNCTION scalarProduct(ptrNodeCheck, ptrNodeStart, ptrNodeEnd) RESULT(pScalar)

!     Declaration
!     - - - - - -
      TYPE(node), POINTER :: ptrNodeCheck, ptrNodeStart, ptrNodeEnd

      REAL(KIND=8), DIMENSION(2) :: a, b
      REAL(KIND=8) :: pScalar

!     Body
!     - - -

      a(1) = ptrNodeEnd%xValue - ptrNodeStart%xValue
      a(2) = ptrNodeEnd%yValue - ptrNodeStart%yValue
      b(1) = ptrNodeCheck%xValue - ptrNodeStart%xValue
      b(2) = ptrNodeCheck%yValue - ptrNodeStart%yValue

      pScalar = a(1) * b(1) - a(2) * b(2)

END FUNCTION

! Procedure 32 : delaunay criterion to accept a cell
! --------------------------------------------------
FUNCTION delaunayCriterion(ptrNode,ptrCell,vertices) RESULT(check)

!     Declaration
!     - - - - - -
      TYPE(node), POINTER :: ptrNode
      TYPE(tria3), POINTER :: ptrCell
      TYPE(nodeDataBase), INTENT(IN) :: vertices

      LOGICAL :: check

      REAL(KIND=8) :: xp,yp,x0,y0,x1,y1,x2,y2,x3,y3,dx10,dy10,dx20,dy20,dx30,dy30,dx12,dy12,dx23,dy23,dx31,dy31, &
                      matA11,matA12,matA22,vecB1,vecB2,b1,b2,b3,dtm,rayonCercle,dx0p,dy0p,distP0Px
      REAL(KIND=8) :: three = 3.0

!     Body
!     - - -

      xp = ptrNode%xValue
      yp = ptrNode%yValue

      x1 = vertices%values(ptrCell%node1)%xValue
      y1 = vertices%values(ptrCell%node1)%yValue

      x2 = vertices%values(ptrCell%node2)%xValue
      y2 = vertices%values(ptrCell%node2)%yValue

      x3 = vertices%values(ptrCell%node3)%xValue
      y3 = vertices%values(ptrCell%node3)%yValue

      dx12 = x1 - x2
      dx23 = x2 - x3
      dx31 = x3 - x1

      dy12 = y1 - y2
      dy23 = y2 - y3
      dy31 = y3 - y1

      matA11 = dx12*dx12 + dx23*dx23 + dx31*dx31
      matA12 = dx12*dy12 + dx23*dy23 + dx31*dy31
      matA22 = dy12*dy12 + dy23*dy23 + dy31*dy31

      b1 = 0.5 * ( ( (x1*x1)-(x2*x2) ) + ( (y1*y1)-(y2*y2) ) )
      b2 = 0.5 * ( ( (x2*x2)-(x3*x3) ) + ( (y2*y2)-(y3*y3) ) )
      b3 = 0.5 * ( ( (x3*x3)-(x1*x1) ) + ( (y3*y3)-(y1*y1) ) )

      vecB1 = dx12 * b1 + dx23 * b2 + dx31 * b3
      vecB2 = dy12 * b1 + dy23 * b2 + dy31 * b3

      dtm = matA11 * matA22 - matA12 * matA12
      x0 = (vecB1 * matA22 - vecB2 * matA12) / dtm
      y0 = (vecB2 * matA11 - vecB1 * matA12) / dtm

      dx10 = x1 - x0
      dx20 = x2 - x0
      dx30 = x3 - x0

      dy10 = y1 - y0
      dy20 = y2 - y0
      dy30 = y3 - y0

      rayonCercle = dx10*dx10 + dy10*dy10
      rayonCercle = rayonCercle + dx20*dx20 + dy20 * dy20
      rayonCercle = ( rayonCercle + dx30*dx30 + dy30 * dy30 ) / three

      dx0p = xp - x0
      dy0p = yp - y0
      distP0Px = dx0p*dx0p + dy0p*dy0p

      check = .FALSE.

      IF ( distP0Px <= rayonCercle ) THEN
         check = .TRUE.
      ENDIF

END FUNCTION

END PROGRAM gmshDriver