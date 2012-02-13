! $Date$ 
! $Revision$
! $Author$


!  ------------------ FGetIsosurface ------------------------ 

integer function FGetIsosurface(vdata, have_tdata, tdata, have_iblank, iblank_cell, level, &
     xplt, nx, yplt, ny, zplt, nz,&
     xyzverts, nxyzverts, triangles, ntriangles)

  implicit none
     
  integer, intent(in) :: nx, ny, nz
  integer, intent(in) :: have_tdata, have_iblank
  real, dimension(0:nx,0:ny,0:nz), intent(in) :: vdata, tdata
  integer, dimension(0:nx-1,0:ny-1,0:nz-1), intent(in) :: iblank_cell
  real, intent(in) :: level
  real, intent(in), dimension(0:nx) :: xplt
  real, intent(in), dimension(0:ny) :: yplt
  real, intent(in), dimension(0:nz) :: zplt
     
  real, dimension(:), pointer, intent(out) :: xyzverts
  integer, dimension(:), pointer, intent(out) :: triangles
  integer, intent(out) :: ntriangles, nxyzverts
  
  
  real, dimension(0:1) :: xx, yy, zz
  integer, dimension(0:23) :: nodeindexes
  integer, dimension(0:35) :: closestnodes
  real, dimension(0:7) :: vals, tvals
  real, dimension(0:35) :: xyzv,tv
  integer :: nxyzv
  integer, dimension(0:11) :: tris
  integer :: ntris
  integer :: nxyzverts_MAX, ntriangles_MAX
  real :: vmin, vmax
  
  integer :: i, j, k, n
  integer :: returnval
  integer :: FGetIsobox,UpdateIsosurface
     
  integer, dimension(0:3) :: ixmin=(/0,1,4,5/), ixmax=(/2,3,6,7/)
  integer, dimension(0:3) :: iymin=(/0,3,4,7/), iymax=(/1,2,5,6/)
  integer, dimension(0:3) :: izmin=(/0,1,2,3/), izmax=(/4,5,6,7/)
  
  nullify(xyzverts)
  nullify(triangles)
  ntriangles=0
  nxyzverts=0
  nxyzverts_MAX=1000
  ntriangles_MAX=1000
  allocate(xyzverts(3*nxyzverts_MAX))
  allocate(triangles(3*ntriangles_MAX))
     
  do i=0, nx-2
    xx(0)=xplt(i)
    xx(1)=xplt(i+1)
    do j=0,ny-2
      yy(0)=yplt(j);
      yy(1)=yplt(j+1);
      do k=0,nz-2
        if(have_iblank.eq.1.and.iblank_cell(i,j,k).eq.0)continue
        
        vals(0)=vdata(  i,  j,  k)
        vals(1)=vdata(  i,j+1,  k)
        vals(2)=vdata(i+1,j+1,  k)
        vals(3)=vdata(i+1,  j,  k)
        vals(4)=vdata(  i,  j,k+1)
        vals(5)=vdata(  i,j+1,k+1)
        vals(6)=vdata(i+1,j+1,k+1)
        vals(7)=vdata(i+1,  j,k+1)

        vmin=min(vals(0),vals(1),vals(2),vals(3),vals(4),vals(5),vals(6),vals(7))
        vmax=max(vals(0),vals(1),vals(2),vals(3),vals(4),vals(5),vals(6),vals(7))
        if(vmin.gt.level.or.vmax.lt.level)continue
           
        zz(0)=zplt(k);
        zz(1)=zplt(k+1);

        do n=0, 3
          nodeindexes(3*ixmin(n))=i
          nodeindexes(3*ixmax(n))=i+1
          nodeindexes(3*iymin(n)+1)=j
          nodeindexes(3*iymax(n)+1)=j+1
          nodeindexes(3*izmin(n)+2)=k
          nodeindexes(3*izmax(n)+2)=k+1
        end do

        if(have_tdata.eq.1)then
          tvals(0)=tdata(  i,  j,  k)
          tvals(1)=tdata(  i,j+1,  k)
          tvals(2)=tdata(i+1,j+1,  k)
          tvals(3)=tdata(i+1,  j,  k)
          tvals(4)=tdata(  i,  j,k+1)
          tvals(5)=tdata(  i,j+1,k+1)
          tvals(6)=tdata(i+1,j+1,k+1)
          tvals(7)=tdata(i+1,  j,k+1)
        endif

        returnval=FGetIsobox(xx,yy,zz,vals,have_tdata,tvals,nodeindexes,level,xyzv,tv,nxyzv,tris,ntris,closestnodes)

        if(nxyzv.gt.0.or.ntris.gt.0)then
          if(UpdateIsosurface(xyzv, nxyzv, tris, ntris, closestnodes, xyzverts, nxyzverts, nxyzverts_MAX, triangles, ntriangles, ntriangles_MAX).ne.0)then
            FGetIsosurface=1
            return
          endif
        endif
      end do
    end do
  end do
  FGetIsosurface=0
  return     
end function FGetIsosurface

!  ------------------ UpdateIsosurface ------------------------ 

integer function UpdateIsosurface(xyzv, nxyzv, tris, ntris, closestnodes, xyzverts, nxyzverts, nxyzverts_MAX, triangles, ntriangles, ntriangles_MAX)
  real, intent(in), dimension(0:3*nxyzv-1) :: xyzv
  integer, intent(in), dimension(0:3*ntris-1) :: tris
  integer, intent(in), dimension(:) :: closestnodes
  real, intent(inout), pointer, dimension(:) :: xyzverts
  integer, intent(inout) :: nxyzverts, nxyzverts_MAX, ntriangles, ntriangles_MAX
  integer, intent(inout), pointer, dimension(:) :: triangles
  real, dimension(:), pointer :: xyzverts_temp
  integer, dimension(:), pointer :: triangles_temp
  
  if(nxyzverts+nxyzv.gt.nxyzverts_MAX)then
    nxyzverts_MAX=nxyzverts_MAX+1000
    
    if(nxyzverts.gt.0)then
      allocate(xyzverts_temp(0:3*nxyzverts-1))
      xyzverts_temp(0:3*nxyzverts-1)=xyzverts(0:3*nxyzverts-1)
      deallocate(xyzverts)    
      allocate(xyzverts(0:3*nxyzverts_MAX-1))
      xyzverts(0:3*nxyzverts-1)=xyzverts_temp(0:3*nxyzverts-1)
      deallocate(xyzverts_temp)
    endif
  endif
  if(ntriangles+ntris.gt.ntriangles_MAX)then
    ntriangles_MAX=ntriangles_MAX+1000
    
    if(ntriangles.gt.0)then
      allocate(triangles_temp(0:3*ntriangles-1))
      triangles_temp(0:3*ntriangles-1)=triangles(0:3*ntriangles-1)
      deallocate(triangles)    
      allocate(triangles(0:3*ntriangles_MAX-1))
      triangles(0:3*ntriangles-1)=triangles_temp(0:3*ntriangles-1)
      deallocate(triangles_temp)
    endif
  endif
  xyzverts(3*nxyzverts:3*nxyzverts+3*nxyzv-1)=xyzv(0:3*nxyzv-1)
  triangles(3*ntriangles:3*ntriangles+3*ntris-1)=tris(0:3*ntris-1)
  UpdateIsosurface=0
  return
end function UpdateIsosurface

!  ------------------ FMIX ------------------------ 

real function FMIX(f,a,b)
  implicit none
  real, intent(in) :: f, a, b
  
    
  FMIX = (1.0-f)*a + f*b
  return
end function fMIX

!  ------------------ FGetIsobox ------------------------ 

integer function FGetIsobox(x,y,z,vals,have_tvals,tvals,nodeindexes,level,xyzv,tv,nxyzv,tris,ntris,closestnodes)
implicit none
real, dimension(0:1), intent(in) :: x, y, z
integer, intent(in) :: have_tvals
real, dimension(0:7), intent(in) :: vals,tvals
integer, dimension(0:23), intent(in) :: nodeindexes
real, intent(in) :: level
real, intent(out), dimension(0:60) :: xyzv,tv
integer, intent(out) :: nxyzv
integer, intent(out), dimension(0:60) :: tris
integer, intent(out) :: ntris
integer, dimension(0:35), intent(out) :: closestnodes
real :: FMIX

integer, dimension(0:14) :: compcase=(/0,0,0,-1,0,0,-1,-1,0,0,0,0,-1,-1,0/)
!int compcase[]=                      {0,0,0,-1,0,0,-1,-1,0,0,0,0,-1,-1,0};

integer, dimension(0:11,0:1) :: edge2vertex                                              
integer, dimension(0:1,0:11) :: edge2vertexT=(/0,1,1,2,2,3,0,3,&
                                              0,4,1,5,2,6,3,7,&
                                              4,5,5,6,6,7,4,7/)
!int edge2vertex[12][2]={
!  {0,1},{1,2},{2,3},{0,3},
!  {0,4},{1,5},{2,6},{3,7},
!  {4,5},{5,6},{6,7},{4,7}
!};

integer, pointer, dimension(:) :: case2
integer, target,dimension(0:255,0:9) :: cases
integer, dimension(0:9,0:255) :: casesT=(/&
0,0,0,0,0,0,0,0, 0,  0,0,1,2,3,4,5,6,7, 1,  1,1,2,3,0,5,6,7,4, 1,  2,&
1,2,3,0,5,6,7,4, 2,  3,2,3,0,1,6,7,4,5, 1,  4,0,4,5,1,3,7,6,2, 3,  5,&
2,3,0,1,6,7,4,5, 2,  6,3,0,1,2,7,4,5,6, 5,  7,3,0,1,2,7,4,5,6, 1,  8,&
0,1,2,3,4,5,6,7, 2,  9,3,7,4,0,2,6,5,1, 3, 10,2,3,0,1,6,7,4,5, 5, 11,&
3,0,1,2,7,4,5,6, 2, 12,1,2,3,0,5,6,7,4, 5, 13,0,1,2,3,4,5,6,7, 5, 14,&
0,1,2,3,4,5,6,7, 8, 15,4,0,3,7,5,1,2,6, 1, 16,4,5,1,0,7,6,2,3, 2, 17,&
1,2,3,0,5,6,7,4, 3, 18,5,1,0,4,6,2,3,7, 5, 19,2,3,0,1,6,7,4,5, 4, 20,&
4,5,1,0,7,6,2,3, 6, 21,2,3,0,1,6,7,4,5, 6, 22,3,0,1,2,7,4,5,6,14, 23,&
4,5,1,0,7,6,2,3, 3, 24,7,4,0,3,6,5,1,2, 5, 25,2,6,7,3,1,5,4,0, 7, 26,&
3,0,1,2,7,4,5,6, 9, 27,2,6,7,3,1,5,4,0, 6, 28,4,0,3,7,5,1,2,6,11, 29,&
0,1,2,3,4,5,6,7,12, 30,0,0,0,0,0,0,0,0, 0,  0,5,4,7,6,1,0,3,2, 1, 32,&
0,3,7,4,1,2,6,5, 3, 33,1,0,4,5,2,3,7,6, 2, 34,4,5,1,0,7,6,2,3, 5, 35,&
2,3,0,1,6,7,4,5, 3, 36,3,7,4,0,2,6,5,1, 7, 37,6,2,1,5,7,3,0,4, 5, 38,&
0,1,2,3,4,5,6,7, 9, 39,3,0,1,2,7,4,5,6, 4, 40,3,7,4,0,2,6,5,1, 6, 41,&
5,6,2,1,4,7,3,0, 6, 42,3,0,1,2,7,4,5,6,11, 43,3,0,1,2,7,4,5,6, 6, 44,&
1,2,3,0,5,6,7,4,12, 45,0,1,2,3,4,5,6,7,14, 46,0,0,0,0,0,0,0,0, 0,  0,&
5,1,0,4,6,2,3,7, 2, 48,1,0,4,5,2,3,7,6, 5, 49,0,4,5,1,3,7,6,2, 5, 50,&
4,5,1,0,7,6,2,3, 8, 51,4,7,6,5,0,3,2,1, 6, 52,1,0,4,5,2,3,7,6,12, 53,&
4,5,1,0,7,6,2,3,11, 54,0,0,0,0,0,0,0,0, 0,  0,5,1,0,4,6,2,3,7, 6, 56,&
1,0,4,5,2,3,7,6,14, 57,0,4,5,1,3,7,6,2,12, 58,0,0,0,0,0,0,0,0, 0,  0,&
4,0,3,7,5,1,2,6,10, 60,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
0,0,0,0,0,0,0,0, 0,  0,6,7,3,2,5,4,0,1, 1, 64,0,1,2,3,4,5,6,7, 4, 65,&
1,0,4,5,2,3,7,6, 3, 66,0,4,5,1,3,7,6,2, 6, 67,2,1,5,6,3,0,4,7, 2, 68,&
6,7,3,2,5,4,0,1, 6, 69,5,6,2,1,4,7,3,0, 5, 70,0,1,2,3,4,5,6,7,11, 71,&
3,0,1,2,7,4,5,6, 3, 72,0,1,2,3,4,5,6,7, 6, 73,7,4,0,3,6,5,1,2, 7, 74,&
2,3,0,1,6,7,4,5,12, 75,7,3,2,6,4,0,1,5, 5, 76,1,2,3,0,5,6,7,4,14, 77,&
1,2,3,0,5,6,7,4, 9, 78,0,0,0,0,0,0,0,0, 0,  0,4,0,3,7,5,1,2,6, 3, 80,&
0,3,7,4,1,2,6,5, 6, 81,2,3,0,1,6,7,4,5, 7, 82,5,1,0,4,6,2,3,7,12, 83,&
2,1,5,6,3,0,4,7, 6, 84,0,1,2,3,4,5,6,7,10, 85,5,6,2,1,4,7,3,0,12, 86,&
0,0,0,0,0,0,0,0, 0,  0,0,1,2,3,4,5,6,7, 7, 88,7,4,0,3,6,5,1,2,12, 89,&
3,0,1,2,7,4,5,6,13, 90,0,0,0,0,0,0,0,0, 0,  0,7,3,2,6,4,0,1,5,12, 92,&
0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
5,4,7,6,1,0,3,2, 2, 96,6,2,1,5,7,3,0,4, 6, 97,2,1,5,6,3,0,4,7, 5, 98,&
2,1,5,6,3,0,4,7,14, 99,1,5,6,2,0,4,7,3, 5,100,1,5,6,2,0,4,7,3,12,101,&
1,5,6,2,0,4,7,3, 8,102,0,0,0,0,0,0,0,0, 0,  0,5,4,7,6,1,0,3,2, 6,104,&
0,4,5,1,3,7,6,2,10,105,2,1,5,6,3,0,4,7,12,106,0,0,0,0,0,0,0,0, 0,  0,&
5,6,2,1,4,7,3,0,11,108,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
0,0,0,0,0,0,0,0, 0,  0,7,6,5,4,3,2,1,0, 5,112,0,4,5,1,3,7,6,2,11,113,&
6,5,4,7,2,1,0,3, 9,114,0,0,0,0,0,0,0,0, 0,  0,1,5,6,2,0,4,7,3,14,116,&
0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
7,6,5,4,3,2,1,0,12,120,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,7,6,5,4,3,2,1,0, 1,128,&
0,1,2,3,4,5,6,7, 3,129,1,2,3,0,5,6,7,4, 4,130,1,2,3,0,5,6,7,4, 6,131,&
7,4,0,3,6,5,1,2, 3,132,1,5,6,2,0,4,7,3, 7,133,1,5,6,2,0,4,7,3, 6,134,&
3,0,1,2,7,4,5,6,12,135,3,2,6,7,0,1,5,4, 2,136,4,0,3,7,5,1,2,6, 5,137,&
7,4,0,3,6,5,1,2, 6,138,2,3,0,1,6,7,4,5,14,139,6,7,3,2,5,4,0,1, 5,140,&
2,3,0,1,6,7,4,5, 9,141,1,2,3,0,5,6,7,4,11,142,0,0,0,0,0,0,0,0, 0,  0,&
4,0,3,7,5,1,2,6, 2,144,3,7,4,0,2,6,5,1, 5,145,7,6,5,4,3,2,1,0, 6,146,&
1,0,4,5,2,3,7,6,11,147,4,0,3,7,5,1,2,6, 6,148,3,7,4,0,2,6,5,1,12,149,&
1,0,4,5,2,3,7,6,10,150,0,0,0,0,0,0,0,0, 0,  0,0,3,7,4,1,2,6,5, 5,152,&
4,0,3,7,5,1,2,6, 8,153,0,3,7,4,1,2,6,5,12,154,0,0,0,0,0,0,0,0, 0,  0,&
0,3,7,4,1,2,6,5,14,156,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
0,0,0,0,0,0,0,0, 0,  0,5,1,0,4,6,2,3,7, 3,160,1,2,3,0,5,6,7,4, 7,161,&
1,0,4,5,2,3,7,6, 6,162,4,5,1,0,7,6,2,3,12,163,3,0,1,2,7,4,5,6, 7,164,&
0,1,2,3,4,5,6,7,13,165,6,2,1,5,7,3,0,4,12,166,0,0,0,0,0,0,0,0, 0,  0,&
3,2,6,7,0,1,5,4, 6,168,4,0,3,7,5,1,2,6,12,169,1,2,3,0,5,6,7,4,10,170,&
0,0,0,0,0,0,0,0, 0,  0,6,7,3,2,5,4,0,1,12,172,0,0,0,0,0,0,0,0, 0,  0,&
0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,6,5,4,7,2,1,0,3, 5,176,&
0,4,5,1,3,7,6,2, 9,177,0,4,5,1,3,7,6,2,14,178,0,0,0,0,0,0,0,0, 0,  0,&
6,5,4,7,2,1,0,3,12,180,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
0,0,0,0,0,0,0,0, 0,  0,5,4,7,6,1,0,3,2,11,184,0,0,0,0,0,0,0,0, 0,  0,&
0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
7,3,2,6,4,0,1,5, 2,192,6,5,4,7,2,1,0,3, 6,193,7,3,2,6,4,0,1,5, 6,194,&
0,3,7,4,1,2,6,5,10,195,3,2,6,7,0,1,5,4, 5,196,3,2,6,7,0,1,5,4,12,197,&
3,2,6,7,0,1,5,4,14,198,0,0,0,0,0,0,0,0, 0,  0,2,6,7,3,1,5,4,0, 5,200,&
0,3,7,4,1,2,6,5,11,201,2,6,7,3,1,5,4,0,12,202,0,0,0,0,0,0,0,0, 0,  0,&
3,2,6,7,0,1,5,4, 8,204,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
0,0,0,0,0,0,0,0, 0,  0,5,4,7,6,1,0,3,2, 5,208,3,7,4,0,2,6,5,1,14,209,&
5,4,7,6,1,0,3,2,12,210,0,0,0,0,0,0,0,0, 0,  0,4,7,6,5,0,3,2,1,11,212,&
0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
6,7,3,2,5,4,0,1, 9,216,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,4,7,6,5,0,3,2,1, 5,224,&
4,7,6,5,0,3,2,1,12,225,1,5,6,2,0,4,7,3,11,226,0,0,0,0,0,0,0,0, 0,  0,&
7,6,5,4,3,2,1,0, 9,228,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
0,0,0,0,0,0,0,0, 0,  0,2,6,7,3,1,5,4,0,14,232,0,0,0,0,0,0,0,0, 0,  0,&
0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
5,4,7,6,1,0,3,2, 8,240,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,0,0,0,0,0,0,0,0, 0,  0,&
0,0,0,0,0,0,0,0, 0,  0&
/)

!int cases[256][10]={
!{0,0,0,0,0,0,0,0, 0,  0},{0,1,2,3,4,5,6,7, 1,  1},{1,2,3,0,5,6,7,4, 1,  2},
!{1,2,3,0,5,6,7,4, 2,  3},{2,3,0,1,6,7,4,5, 1,  4},{0,4,5,1,3,7,6,2, 3,  5},
!{2,3,0,1,6,7,4,5, 2,  6},{3,0,1,2,7,4,5,6, 5,  7},{3,0,1,2,7,4,5,6, 1,  8},
!{0,1,2,3,4,5,6,7, 2,  9},{3,7,4,0,2,6,5,1, 3, 10},{2,3,0,1,6,7,4,5, 5, 11},
!{3,0,1,2,7,4,5,6, 2, 12},{1,2,3,0,5,6,7,4, 5, 13},{0,1,2,3,4,5,6,7, 5, 14},
!{0,1,2,3,4,5,6,7, 8, 15},{4,0,3,7,5,1,2,6, 1, 16},{4,5,1,0,7,6,2,3, 2, 17},
!{1,2,3,0,5,6,7,4, 3, 18},{5,1,0,4,6,2,3,7, 5, 19},{2,3,0,1,6,7,4,5, 4, 20},
!{4,5,1,0,7,6,2,3, 6, 21},{2,3,0,1,6,7,4,5, 6, 22},{3,0,1,2,7,4,5,6,14, 23},
!{4,5,1,0,7,6,2,3, 3, 24},{7,4,0,3,6,5,1,2, 5, 25},{2,6,7,3,1,5,4,0, 7, 26},
!{3,0,1,2,7,4,5,6, 9, 27},{2,6,7,3,1,5,4,0, 6, 28},{4,0,3,7,5,1,2,6,11, 29},
!{0,1,2,3,4,5,6,7,12, 30},{0,0,0,0,0,0,0,0, 0,  0},{5,4,7,6,1,0,3,2, 1, 32},
!{0,3,7,4,1,2,6,5, 3, 33},{1,0,4,5,2,3,7,6, 2, 34},{4,5,1,0,7,6,2,3, 5, 35},
!{2,3,0,1,6,7,4,5, 3, 36},{3,7,4,0,2,6,5,1, 7, 37},{6,2,1,5,7,3,0,4, 5, 38},
!{0,1,2,3,4,5,6,7, 9, 39},{3,0,1,2,7,4,5,6, 4, 40},{3,7,4,0,2,6,5,1, 6, 41},
!{5,6,2,1,4,7,3,0, 6, 42},{3,0,1,2,7,4,5,6,11, 43},{3,0,1,2,7,4,5,6, 6, 44},
!{1,2,3,0,5,6,7,4,12, 45},{0,1,2,3,4,5,6,7,14, 46},{0,0,0,0,0,0,0,0, 0,  0},
!{5,1,0,4,6,2,3,7, 2, 48},{1,0,4,5,2,3,7,6, 5, 49},{0,4,5,1,3,7,6,2, 5, 50},
!{4,5,1,0,7,6,2,3, 8, 51},{4,7,6,5,0,3,2,1, 6, 52},{1,0,4,5,2,3,7,6,12, 53},
!{4,5,1,0,7,6,2,3,11, 54},{0,0,0,0,0,0,0,0, 0,  0},{5,1,0,4,6,2,3,7, 6, 56},
!{1,0,4,5,2,3,7,6,14, 57},{0,4,5,1,3,7,6,2,12, 58},{0,0,0,0,0,0,0,0, 0,  0},
!{4,0,3,7,5,1,2,6,10, 60},{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},
!{0,0,0,0,0,0,0,0, 0,  0},{6,7,3,2,5,4,0,1, 1, 64},{0,1,2,3,4,5,6,7, 4, 65},
!{1,0,4,5,2,3,7,6, 3, 66},{0,4,5,1,3,7,6,2, 6, 67},{2,1,5,6,3,0,4,7, 2, 68},
!{6,7,3,2,5,4,0,1, 6, 69},{5,6,2,1,4,7,3,0, 5, 70},{0,1,2,3,4,5,6,7,11, 71},
!{3,0,1,2,7,4,5,6, 3, 72},{0,1,2,3,4,5,6,7, 6, 73},{7,4,0,3,6,5,1,2, 7, 74},
!{2,3,0,1,6,7,4,5,12, 75},{7,3,2,6,4,0,1,5, 5, 76},{1,2,3,0,5,6,7,4,14, 77},
!{1,2,3,0,5,6,7,4, 9, 78},{0,0,0,0,0,0,0,0, 0,  0},{4,0,3,7,5,1,2,6, 3, 80},
!{0,3,7,4,1,2,6,5, 6, 81},{2,3,0,1,6,7,4,5, 7, 82},{5,1,0,4,6,2,3,7,12, 83},
!{2,1,5,6,3,0,4,7, 6, 84},{0,1,2,3,4,5,6,7,10, 85},{5,6,2,1,4,7,3,0,12, 86},
!{0,0,0,0,0,0,0,0, 0,  0},{0,1,2,3,4,5,6,7, 7, 88},{7,4,0,3,6,5,1,2,12, 89},
!{3,0,1,2,7,4,5,6,13, 90},{0,0,0,0,0,0,0,0, 0,  0},{7,3,2,6,4,0,1,5,12, 92},
!{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},
!{5,4,7,6,1,0,3,2, 2, 96},{6,2,1,5,7,3,0,4, 6, 97},{2,1,5,6,3,0,4,7, 5, 98},
!{2,1,5,6,3,0,4,7,14, 99},{1,5,6,2,0,4,7,3, 5,100},{1,5,6,2,0,4,7,3,12,101},
!{1,5,6,2,0,4,7,3, 8,102},{0,0,0,0,0,0,0,0, 0,  0},{5,4,7,6,1,0,3,2, 6,104},
!{0,4,5,1,3,7,6,2,10,105},{2,1,5,6,3,0,4,7,12,106},{0,0,0,0,0,0,0,0, 0,  0},
!{5,6,2,1,4,7,3,0,11,108},{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},
!{0,0,0,0,0,0,0,0, 0,  0},{7,6,5,4,3,2,1,0, 5,112},{0,4,5,1,3,7,6,2,11,113},
!{6,5,4,7,2,1,0,3, 9,114},{0,0,0,0,0,0,0,0, 0,  0},{1,5,6,2,0,4,7,3,14,116},
!{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},
!{7,6,5,4,3,2,1,0,12,120},{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},
!{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},
!{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},{7,6,5,4,3,2,1,0, 1,128},
!{0,1,2,3,4,5,6,7, 3,129},{1,2,3,0,5,6,7,4, 4,130},{1,2,3,0,5,6,7,4, 6,131},
!{7,4,0,3,6,5,1,2, 3,132},{1,5,6,2,0,4,7,3, 7,133},{1,5,6,2,0,4,7,3, 6,134},
!{3,0,1,2,7,4,5,6,12,135},{3,2,6,7,0,1,5,4, 2,136},{4,0,3,7,5,1,2,6, 5,137},
!{7,4,0,3,6,5,1,2, 6,138},{2,3,0,1,6,7,4,5,14,139},{6,7,3,2,5,4,0,1, 5,140},
!{2,3,0,1,6,7,4,5, 9,141},{1,2,3,0,5,6,7,4,11,142},{0,0,0,0,0,0,0,0, 0,  0},
!{4,0,3,7,5,1,2,6, 2,144},{3,7,4,0,2,6,5,1, 5,145},{7,6,5,4,3,2,1,0, 6,146},
!{1,0,4,5,2,3,7,6,11,147},{4,0,3,7,5,1,2,6, 6,148},{3,7,4,0,2,6,5,1,12,149},
!{1,0,4,5,2,3,7,6,10,150},{0,0,0,0,0,0,0,0, 0,  0},{0,3,7,4,1,2,6,5, 5,152},
!{4,0,3,7,5,1,2,6, 8,153},{0,3,7,4,1,2,6,5,12,154},{0,0,0,0,0,0,0,0, 0,  0},
!{0,3,7,4,1,2,6,5,14,156},{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},
!{0,0,0,0,0,0,0,0, 0,  0},{5,1,0,4,6,2,3,7, 3,160},{1,2,3,0,5,6,7,4, 7,161},
!{1,0,4,5,2,3,7,6, 6,162},{4,5,1,0,7,6,2,3,12,163},{3,0,1,2,7,4,5,6, 7,164},
!{0,1,2,3,4,5,6,7,13,165},{6,2,1,5,7,3,0,4,12,166},{0,0,0,0,0,0,0,0, 0,  0},
!{3,2,6,7,0,1,5,4, 6,168},{4,0,3,7,5,1,2,6,12,169},{1,2,3,0,5,6,7,4,10,170},
!{0,0,0,0,0,0,0,0, 0,  0},{6,7,3,2,5,4,0,1,12,172},{0,0,0,0,0,0,0,0, 0,  0},
!{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},{6,5,4,7,2,1,0,3, 5,176},
!{0,4,5,1,3,7,6,2, 9,177},{0,4,5,1,3,7,6,2,14,178},{0,0,0,0,0,0,0,0, 0,  0},
!{6,5,4,7,2,1,0,3,12,180},{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},
!{0,0,0,0,0,0,0,0, 0,  0},{5,4,7,6,1,0,3,2,11,184},{0,0,0,0,0,0,0,0, 0,  0},
!{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},
!{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},
!{7,3,2,6,4,0,1,5, 2,192},{6,5,4,7,2,1,0,3, 6,193},{7,3,2,6,4,0,1,5, 6,194},
!{0,3,7,4,1,2,6,5,10,195},{3,2,6,7,0,1,5,4, 5,196},{3,2,6,7,0,1,5,4,12,197},
!{3,2,6,7,0,1,5,4,14,198},{0,0,0,0,0,0,0,0, 0,  0},{2,6,7,3,1,5,4,0, 5,200},
!{0,3,7,4,1,2,6,5,11,201},{2,6,7,3,1,5,4,0,12,202},{0,0,0,0,0,0,0,0, 0,  0},
!{3,2,6,7,0,1,5,4, 8,204},{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},
!{0,0,0,0,0,0,0,0, 0,  0},{5,4,7,6,1,0,3,2, 5,208},{3,7,4,0,2,6,5,1,14,209},
!{5,4,7,6,1,0,3,2,12,210},{0,0,0,0,0,0,0,0, 0,  0},{4,7,6,5,0,3,2,1,11,212},
!{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},
!{6,7,3,2,5,4,0,1, 9,216},{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},
!{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},
!{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},{4,7,6,5,0,3,2,1, 5,224},
!{4,7,6,5,0,3,2,1,12,225},{1,5,6,2,0,4,7,3,11,226},{0,0,0,0,0,0,0,0, 0,  0},
!{7,6,5,4,3,2,1,0, 9,228},{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},
!{0,0,0,0,0,0,0,0, 0,  0},{2,6,7,3,1,5,4,0,14,232},{0,0,0,0,0,0,0,0, 0,  0},
!{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},
!{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},
!{5,4,7,6,1,0,3,2, 8,240},{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},
!{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},
!{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},
!{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},
!{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},{0,0,0,0,0,0,0,0, 0,  0},
!{0,0,0,0,0,0,0,0, 0,  0}
!};

integer, target,dimension(0:14,0:12) :: pathcclist
integer, dimension(0:12,0:14) :: pathcclistT=(/&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   3, 0, 1, 2,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   6,0,1,2,2,3,0,-1,-1,-1,-1,-1,-1,&
   6,0,1,2,3,4,5,-1,-1,-1,-1,-1,-1,&
   6,0,1,2,3,4,5,-1,-1,-1,-1,-1,-1,&
   9,0,1,2,2,3,4,0,2,4,-1,-1,-1,&
   9,0,1,2,2,3,0,4,5,6,-1,-1,-1,&
   9,0,1,2,3,4,5,6,7,8,-1,-1,-1,&
   6,0,1,2,2,3,0,-1,-1,-1,-1,-1,-1,&
  12,0,1,5,1,4,5,1,2,4,2,3,4,&
  12,0,1,2,0,2,3,4,5,6,4,6,7,&
  12,0,1,5,1,4,5,1,2,4,2,3,4,&
  12,0,1,2,3,4,5,3,5,6,3,6,7,&
  12,0,1,2,3,4,5,6,7,8,9,10,11,&
  12,0,1,5,1,4,5,1,2,4,2,3,4&
  /)
!int pathcclist[15][13]={
!  { 0},
!  { 3,0,1,2},
!  { 6,0,1,2,2,3,0},
!  { 6,0,1,2,3,4,5},
!  { 6,0,1,2,3,4,5},
!  { 9,0,1,2,2,3,4,0,2,4},
!  { 9,0,1,2,2,3,0,4,5,6},
!  { 9,0,1,2,3,4,5,6,7,8},
!  { 6,0,1,2,2,3,0},
!  {12,0,1,5,1,4,5,1,2,4,2,3,4},
!  {12,0,1,2,0,2,3,4,5,6,4,6,7},
!  {12,0,1,5,1,4,5,1,2,4,2,3,4},
!  {12,0,1,2,3,4,5,3,5,6,3,6,7},
!  {12,0,1,2,3,4,5,6,7,8,9,10,11},
!  {12,0,1,5,1,4,5,1,2,4,2,3,4}
!};
integer, target,dimension(0:14,0:19) :: pathcclist2
integer, dimension(0:19,0:14) :: pathcclist2T=(/&
    0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
    0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
    0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   12, 0, 1, 2, 0, 2, 3, 4, 5, 6, 4, 6, 7,-1,-1,-1,-1,-1,-1,-1,&
    0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
    0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   15, 0, 1, 2, 0, 2, 3, 4, 5, 6, 7, 8, 9, 7, 9,10,-1,-1,-1,-1,&
   15, 0, 1, 2, 3, 4, 5, 3, 5, 7, 3, 7, 8, 5, 6, 7,-1,-1,-1,-1,&
    0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
    0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   12, 0, 1, 2, 0, 2, 3, 4, 5, 6, 4, 6, 7,-1,-1,-1,-1,-1,-1,-1,&
    0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   12, 0, 1, 2, 3, 4, 6, 3, 6, 7, 4, 5, 6,-1,-1,-1,-1,-1,-1,-1,&
   12, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,-1,-1,-1,-1,-1,-1,-1,&
    0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1&
   /)

!int pathcclist2[15][19]={
!  { 0},
!  { 0},
!  { 0},
!  { 12,0,1,2,0,2,3,4,5,6,4,6,7},
!  { 0},
!  { 0},
!  { 15,0,1,2,0,2,3,4,5,6,7,8,9,7,9,10},
!  { 15,0,1,2,3,4,5,3,5,7,3,7,8,5,6,7},
!  { 0},
!  { 0},
!  { 12,0,1,2,0,2,3,4,5,6,4,6,7},
!  { 0},
!  { 12,0,1,2,3,4,6,3,6,7,4,5,6},
!  { 12,0,1,2,3,4,5,6,7,8,9,10,11},
!  { 0}
!};

integer, pointer,dimension(:) :: path
integer, target,dimension(0:12,0:14) :: pathccwlist
integer, dimension(0:14,0:12) :: pathccwlistT=(/&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   3, 0, 2, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   6, 0, 2, 1, 0, 3, 2,-1,-1,-1,-1,-1,-1,&
   6, 0, 2, 1, 3, 5, 4,-1,-1,-1,-1,-1,-1,&
   6, 0, 2, 1, 3, 5, 4,-1,-1,-1,-1,-1,-1,&
   9, 0, 2, 1, 2, 4, 3, 0, 4, 2,-1,-1,-1,&
   9, 0, 2, 1, 0, 3, 2, 4, 6, 5,-1,-1,-1,&
   9, 0, 2, 1, 3, 5, 4, 6, 8, 7,-1,-1,-1,&
   6, 0, 2, 1, 0, 3, 2,-1,-1,-1,-1,-1,-1,&
  12, 0, 5, 1, 1, 5, 4, 1, 4, 2, 2, 4, 3,&
  12, 0, 2, 1, 0, 3, 2, 4, 6, 5, 4, 7, 6,&
  12, 0, 5, 1, 1, 5, 4, 1, 4, 2, 2, 4, 3,&
  12, 0, 2, 1, 3, 5, 4, 3, 6, 5, 3, 7, 6,&
  12, 0, 2, 1, 3, 5, 4, 6, 8, 7, 9,11,10,&
  12, 0, 5, 1, 1, 5, 4, 1, 4, 2, 2, 4, 3&
   /)

!int pathccwlist[15][13]={
!  { 0},
!  { 3,0,2,1},
!  { 6,0,2,1,0,3,2},
!  { 6,0,2,1,3,5,4},
!  { 6,0,2,1,3,5,4},
!  { 9,0,2,1,2,4,3,0,4,2},
!  { 9,0,2,1,0,3,2,4,6,5},
!  { 9,0,2,1,3,5,4,6,8,7},
!  { 6,0,2,1,0,3,2},
!  {12,0,5,1,1,5,4,1,4,2,2,4,3},
!  {12,0,2,1,0,3,2,4,6,5,4,7,6},
!  {12,0,5,1,1,5,4,1,4,2,2,4,3},
!  {12,0,2,1,3,5,4,3,6,5,3,7,6},
!  {12,0,2,1,3,5,4,6,8,7,9,11,10},
!  {12,0,5,1,1,5,4,1,4,2,2,4,3}
!};

integer, target,dimension(0:18,0:14) :: pathccwlist2
integer, dimension(0:14,0:18) :: pathccwlist2T=(/&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
  12, 0, 2, 1, 0, 3, 2, 4, 6, 5, 4, 7, 6,-1,-1,-1,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
  15, 0, 2, 1, 0, 3, 2, 4, 6, 5, 7, 9, 8, 7,10, 9,-1,-1,-1,&
  15, 0, 2, 1, 3, 5, 4, 3, 7, 5, 3, 8, 7, 5, 7, 6,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
  12, 0, 2, 1, 0, 3, 2, 4, 6, 5, 4, 7, 6,-1,-1,-1,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
  12, 0, 2, 1, 3, 6, 4, 3, 7, 6, 4, 6, 5,-1,-1,-1,-1,-1,-1,&
  12, 0, 2, 1, 3, 5, 4, 6, 8, 7, 9,11,10,-1,-1,-1,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1&
  /)

!int pathccwlist2[15][19]={
!  { 0},
!  { 0},
!  { 0},
!  { 12,0,2,1,0,3,2,4,6,5,4,7,6},
!  { 0},
!  { 0},
!  { 15,0,2,1,0,3,2,4,6,5,7,9,8,7,10,9},
!  { 15,0,2,1,3,5,4,3,7,5,3,8,7,5,7,6},
!  { 0},
!  { 0},
!  { 12,0,2,1,0,3,2,4,6,5,4,7,6},
!  { 0},
!  { 12,0,2,1,3,6,4,3,7,6,4,6,5},
!  { 12,0,2,1,3,5,4,6,8,7,9,11,10},
!  { 0}
!};

integer, pointer,dimension(:) :: edges
integer, target,dimension(0:12,0:14) :: edgelist
integer, dimension(0:14,0:12) :: edgelistT=(/&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   3, 0, 4, 3,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   4, 0, 4, 7, 2,-1,-1,-1,-1,-1,-1,-1,-1,&
   6, 0, 4, 3, 7,11,10,-1,-1,-1,-1,-1,-1,&
   6, 0, 4, 3, 6,10, 9,-1,-1,-1,-1,-1,-1,&
   5, 0, 3, 7, 6, 5,-1,-1,-1,-1,-1,-1,-1,&
   7, 0, 4, 7, 2, 6,10, 9,-1,-1,-1,-1,-1,&
   9, 4, 8,11, 2, 3, 7, 6,10, 9,-1,-1,-1,&
   4, 4, 7, 6, 5,-1,-1,-1,-1,-1,-1,-1,-1,&
   6, 2, 6, 9, 8, 4, 3,-1,-1,-1,-1,-1,-1,&
   8, 0, 8,11, 3,10, 9, 1, 2,-1,-1,-1,-1,&
   6, 4, 3, 2,10, 9, 5,-1,-1,-1,-1,-1,-1,&
   8, 4, 8,11, 0, 3, 7, 6, 5,-1,-1,-1,-1,&
  12, 0, 4, 3, 7,11,10, 2, 6, 1, 8, 5, 9,&
   6, 3, 7, 6, 9, 8, 0,-1,-1,-1,-1,-1,-1&
  /)

!int edgelist[15][13]={
!  { 0                             },
!  { 3,0,4, 3                      },
!  { 4,0,4, 7, 2                   },
!  { 6,0,4, 3, 7,11,10             },
!  { 6,0,4, 3, 6,10, 9             },
!  { 5,0,3, 7, 6, 5                },
!  { 7,0,4, 7, 2, 6,10,9           },
!  { 9,4,8,11, 2, 3, 7,6,10,9      },
!  { 4,4,7, 6, 5                   },
!  { 6,2,6, 9, 8, 4, 3             },
!  { 8,0,8,11, 3,10, 9,1, 2        },
!  { 6,4,3, 2,10, 9, 5             },
!  { 8,4,8,11, 0, 3, 7,6, 5        },
!  {12,0,4, 3, 7,11,10,2, 6,1,8,5,9},
!  { 6,3,7, 6, 9, 8, 0             }
!};

integer, target,dimension(0:15,0:14) :: edgelist2
integer, dimension(0:14,0:15) :: edgelist2T=(/&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   8, 3, 0,10, 7, 0, 4,11,10,-1,-1,-1,-1,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
  11, 7,10, 9, 4, 0, 4, 9, 0, 9, 6, 2,-1,-1,-1,-1,&
   9, 7,10,11, 3, 4, 8, 9, 6, 2,-1,-1,-1,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   8, 0, 8, 9, 1, 3, 2,10,11,-1,-1,-1,-1,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,&
   8, 0, 3, 4, 8,11, 7, 6, 5,-1,-1,-1,-1,-1,-1,-1,&
  12, 4,11, 8, 0, 5, 1, 7, 3, 2, 9,10, 6,-1,-1,-1,&
   0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1&
  /)
  
!int edgelist2[15][16]={
!  { 0                             },
!  { 0},
!  { 0},
!  { 8,3,0,10,7,0,4,11,10},
!  { 0},
!  { 0},
!  { 11, 7,10,9,4,0,4,9,0,9,6,2},
!  { 9,7,10,11,3,4,8,9,6,2},
!  { 0},
!  { 0},
!  { 8,0,8,9,1,3,2,10,11},
!  { 0},
!  { 8,0,3,4,8,11,7,6,5},
!  { 12,4,11,8,0,5,1,7,3,2,9,10,6},
!  { 0}

integer :: vmin, vmax
integer :: casenum, bigger, sign, n
integer, dimension(0:7) :: prods=(/1,2,4,8,16,32,64,128/);
real, dimension(0:7) :: xxval,yyval,zzval
integer, dimension(0:3) :: ixmin=(/0,1,4,5/), ixmax=(/2,3,6,7/)
integer, dimension(0:3) :: iymin=(/0,3,4,7/), iymax=(/1,2,5,6/)
integer, dimension(0:3) :: izmin=(/0,1,2,3/), izmax=(/4,5,6,7/)
integer :: type2,thistype2
integer :: nedges,npath
integer :: outofbounds, edge, v1, v2
real :: val1, val2, denom, factor
real :: xx, yy, zz

edge2vertex=transpose(edge2vertexT)
cases=transpose(casesT)
pathcclist=transpose(pathcclistT)
pathcclist2=transpose(pathcclist2T)
pathccwlist=transpose(pathccwlistT)
pathccwlist2=transpose(pathccwlist2T)
edgelist=transpose(edgelistT)
edgelist2=transpose(edgelist2T)

closestnodes=0
vmin=min(vals(0),vals(1),vals(2),vals(3),vals(4),vals(5),vals(6),vals(7))
vmax=max(vals(0),vals(1),vals(2),vals(3),vals(4),vals(5),vals(6),vals(7))


nxyzv=0
ntris=0

if(vmin>level.or.vmax<level)then
  FGetIsobox=ntris
  return
endif

casenum=0
bigger=0
sign=1

do n = 0, 7
  if(vals(n)>level)then
    bigger=bigger+1
    casenum = casenum + prods(n);
  endif
end do

! there are more nodes greater than the iso-surface level than below, so 
!   solve the complementary problem 

if(bigger.gt.4)then
  sign=-1
  casenum=0
  do n=0, 7
    if(vals(n)<level)then
      casenum = casenum + prods(n)
    endif
  end do
endif

! stuff min and max grid data into a more convenient form 
!  assuming the following grid numbering scheme

!       5-------6
!     / |      /| 
!   /   |     / | 
!  4 -------7   |
!  |    |   |   |  
!  Z    1---|---2
!  |  Y     |  /
!  |/       |/
!  0--X-----3     


do n=0, 3
  xxval(ixmin(n)) = x(0);
  xxval(ixmax(n)) = x(1);
  yyval(iymin(n)) = y(0);
  yyval(iymax(n)) = y(1);
  zzval(izmin(n)) = z(0);
  zzval(izmax(n)) = z(1);
end do

 if(casenum<=0.or.casenum>=255)then ! no iso-surface 
   FGetIsobox=0
   return
 endif

  case2 => cases(casenum,0:9)
  type2 = case2(8);
  if(type2==0)then
    FGetIsobox=ntris
    return
  endif

  if(compcase(type2).eq.-1)then
    thistype2=sign
  else
    thistype2=1
  endif
  
  if(thistype2.ne.-1)then
    !edges = &(edgelist[type][1]);
    edges => edgelist(type2,1:14)
    if(sign.ge.0)then
     ! path = &(pathcclist[type][1])   !  construct triangles clock wise
      path => pathcclist(type2,1:12)
    else
     ! path = &(pathccwlist[type][1])  !  construct triangles counter clockwise 
      path => pathccwlist(type2,1:14)
    endif
  else
    !edges = &(edgelist2[type][1]);
    edges => edgelist2(type2,1:14)
    if(sign.gt.0)then
     ! path = &(pathcclist2[type][1])  !  construct triangles clock wise
      path => pathcclist2(type2,1:19)
    else
     ! path = &(pathccwlist2[type][1]) !  construct triangles counter clockwise
      path => pathccwlist2(type2,1:14)
    endif   
  endif
  npath = path(-1);
  nedges = edges(-1);
  
  outofbounds=0
  do n=0,nedges-1
    edge = edges(n)
    v1 = case2(edge2vertex(edge,0));
    v2 = case2(edge2vertex(edge,1));
    val1 = vals(v1)-level
    val2 = vals(v2)-level
    denom = val2 - val1
    factor = 0.5
    if(denom.ne.0.0)factor = -val1/denom
    if(factor.lt.0.5)then
      closestnodes(3*n)=nodeindexes(3*v1)
      closestnodes(3*n+1)=nodeindexes(3*v1+1)
      closestnodes(3*n+2)=nodeindexes(3*v1+2)
    else
      closestnodes(3*n)=nodeindexes(3*v2)
      closestnodes(3*n+1)=nodeindexes(3*v2+1)
      closestnodes(3*n+2)=nodeindexes(3*v2+2)
    endif
    if(factor.gt.1.0)then
      ! factor=1.0
      outofbounds=1
    endif
    if(factor.lt.0.0)then
      ! factor=0.0
      outofbounds=1
    endif
    xx = FMIX(factor,xxval(v2),xxval(v1));
    yy = FMIX(factor,yyval(v2),yyval(v1));
    zz = FMIX(factor,zzval(v2),zzval(v1));
    xyzv(3*n) = xx;
    xyzv(3*n+1) = yy;
    xyzv(3*n+2) = zz;
    if(have_tvals.eq.1)then
      tv(n) = FMIX(factor,tvals(v2),tvals(v1));
    endif

  end do
  if(outofbounds.eq.1)then
    write(6,*)"*** warning - computed isosurface vertices are out of bounds for :"
    write(6,*)"case number=",casenum," level=",level
    write(6,*)"values="
    do n=0,7
      write(6,*)vals(n)
    end do
    write(6,*)"x=",x(0),x(1),"y=",y(0),y(1),"z=",z(0),z(1)
  endif

! copy coordinates to output array

  nxyzv = nedges;
  ntris = npath;
  do n=0,npath-1
    tris(n) = path(n)
  end do
  FGetIsobox=ntris
  return
end function FGetIsobox

