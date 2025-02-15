#include "RBCS_OPTIONS.h"

CBOP
C !ROUTINE: RBCS_ADD_TENDENCY

C !INTERFACE: ==========================================================
      SUBROUTINE RBCS_ADD_TENDENCY(
     U                    gTendency,
     I                    k, bi, bj, tracerNum,
     I                    myTime, myIter, myThid )

C !DESCRIPTION:
C     Add to tendency array the contribution from 3-D field relaxation
C hassan: Modified to restore based on zonal mean value instead of local
C         value inside of a cell. Used in combination with a modified:
C         DYNVARS.h
C         external_forcing_surf.F
C         global_sum_tile_merid.F

C !USES: ===============================================================
      IMPLICIT NONE
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#include "DYNVARS.h"
#ifdef ALLOW_PTRACERS
#include "PTRACERS_SIZE.h"
#include "PTRACERS_FIELDS.h"
#endif
#include "RBCS_SIZE.h"
#include "RBCS_PARAMS.h"
#include "RBCS_FIELDS.h"

C !INPUT/OUTPUT PARAMETERS: ============================================
C  gTendency      :: the tendency array
C  k              :: vertical level index
C  bi,bj          :: tile indices
C  tracerNum      :: tracer number (1=Temp, 2=Salt, >2 : ptracer)
C  myTime         :: current time
C  myIter         :: current timestep
C  myThid         :: my Thread Id number
      _RL gTendency(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      INTEGER k, bi, bj
      INTEGER tracerNum
      _RL myTime
      INTEGER myIter
      INTEGER myThid

C !LOCAL VARIABLES: ====================================================
C  i,j            :: loop indices
      INTEGER i,j
      INTEGER irbc
      _RL rbcsVanishingFac
      _RL rec_tauRlx
#ifdef ALLOW_PTRACERS
      INTEGER iTracer
#endif
CEOP

#ifdef ALLOW_RBCS

      IF ( rbcsVanishingTime.GT.0. _d 0 ) THEN
        rbcsVanishingFac =
     &      MAX( 0. _d 0 , 1. _d 0 - myTime / rbcsVanishingTime )
      ELSE
        rbcsVanishingFac = 1. _d 0
      ENDIF

#ifndef DISABLE_RBCS_MOM
      IF ( tracerNum.EQ.-1 .AND. useRBCuVel ) THEN
        rec_tauRlx = rbcsVanishingFac/tauRelaxU
        DO j=0,sNy+1
         DO i=0,sNx+1
          gTendency(i,j) = gTendency(i,j)
     &       - RBC_maskU(i,j,k,bi,bj)*rec_tauRlx
     &        *( mean_U(j,k,bi,bj)- RBCuVel(i,j,k,bi,bj) )
         ENDDO
        ENDDO
      ENDIF
      IF ( tracerNum.EQ.-2 .AND. useRBCvVel ) THEN
        rec_tauRlx = rbcsVanishingFac/tauRelaxV
        DO j=0,sNy+1
         DO i=0,sNx+1
          gTendency(i,j) = gTendency(i,j)
     &       - RBC_maskV(i,j,k,bi,bj)*rec_tauRlx
     &        *( mean_V(j,k,bi,bj)- RBCvVel(i,j,k,bi,bj) )
         ENDDO
        ENDDO
      ENDIF
#endif /* DISABLE_RBCS_MOM */

      IF ( tracerNum.EQ.1 .AND. useRBCtemp ) THEN
        irbc = MIN(maskLEN,tracerNum)
        rec_tauRlx = rbcsVanishingFac/tauRelaxT
        DO j=0,sNy+1
         DO i=0,sNx+1
          gTendency(i,j) = gTendency(i,j)
     &       - RBC_mask(i,j,k,bi,bj,irbc)*rec_tauRlx
     &        *( mean_T(j,k,bi,bj)- RBCtemp(i,j,k,bi,bj) )

         ENDDO
        ENDDO
      ENDIF

      IF ( tracerNum.EQ.2 .AND. useRBCsalt ) THEN
        irbc = MIN(maskLEN,tracerNum)
        rec_tauRlx = rbcsVanishingFac/tauRelaxS
        DO j=0,sNy+1
         DO i=0,sNx+1
          gTendency(i,j) = gTendency(i,j)
     &       - RBC_mask(i,j,k,bi,bj,irbc)*rec_tauRlx
     &        *( mean_S(j,k,bi,bj)- RBCsalt(i,j,k,bi,bj) )
         ENDDO
        ENDDO
      ENDIF

#ifdef ALLOW_PTRACERS
      IF ( usePTRACERS .AND. tracerNum.GT.2 ) THEN
       iTracer = tracerNum-2
       IF ( useRBCpTrNum(iTracer) ) THEN
        irbc = MIN(maskLEN,tracerNum)
        rec_tauRlx = rbcsVanishingFac/tauRelaxPTR(iTracer)
        DO j=0,sNy+1
         DO i=0,sNx+1
          gTendency(i,j) = gTendency(i,j)
     &       - RBC_mask(i,j,k,bi,bj,irbc)*rec_tauRlx
     &        *( pTracer(i,j,k,bi,bj,iTracer)
     &           - RBC_ptracers(i,j,k,bi,bj,iTracer) )
         ENDDO
        ENDDO
       ENDIF
      ENDIF
#endif /* ALLOW_PTRACERS */

#endif /* ALLOW_RBCS */

      RETURN
      END
