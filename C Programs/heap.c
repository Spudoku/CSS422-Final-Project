/*
 * This is a C implementation of malloc( ) and free( ), based on the buddy
 * memory allocation algorithm.
 */
#include <stdio.h> // printf

/*
 * The following global variables are used to simulate memory allocation
 * Cortex-M's SRAM space.
 */
// Heap
char array[0x8000];        // simulate SRAM: 0x2000.0000 - 0x2000.7FFF
int heap_top = 0x20001000; // the top of heap space
int heap_bot = 0x20004FE0; // the address of the last 32B in heap
int max_size = 0x00004000; // maximum allocation: 16KB = 2^14
int min_size = 0x00000020; // minimum allocation: 32B = 2^5

// Memory Control Block: 2^10B = 1KB space
int mcb_top = 0x20006800;    // the top of MCB
int mcb_bot = 0x20006BFE;    // the address of the last MCB entry
int mcb_ent_sz = 0x00000002; // 2B per MCB entry
const int mcb_total = 512;   // # MCB entries: 2^9 = 512 entries
// Note to self: MSB of each MCB will hold status (allocated or not)

/*
 * Convert a Cortex SRAM address to the corresponding array index.
 * @param  sram_addr address of Cortex-M's SRAM space starting at 0x20000000.
 * @return array index.
  aka MCB to array?
 */
int m2a(int sram_addr)
{
  int index = sram_addr - 0x20000000;
  // printf( "m2a: sram_addr = %x array_index = %d\n", sram_addr, index );
  return index;
}

/*
 * Reverse an array index back to the corresponding Cortex SRAM address.
 * @param  array index.
 * @return the corresponding Cortex-M's SRAM address in an integer.
  aka array to MCB?
 */
int a2m(int array_index)
{
  return array_index + 0x20000000;
}

/*
 * In case if you want to print out, all array elements that correspond
 * to MCB: 0x2006800 - 0x20006C00.
 */
void printArray()
{
  printf("memroy ............................\n");
  for (int i = 0; i < 0x8000; i += 4)
    if (a2m(i) >= 0x20006800)
      printf("%x = %x(%d)\n",
             a2m(i), *(int *)&array[i], *(int *)&array[i]);
}

/*
* TODO: _ralloc
_ralloc is _kalloc's helper function that is recursively called to
 * allocate a requested space, using the buddy memory allocation algorithm.
 * Implement it by yourself in step 1.
 *
 * @param  size  the size of a requested memory space
 * @param  left  the address of the left boundary of MCB entries to examine
 * @param  right the address of the right boundary of MCB entries to examine
 * @return the address of Cortex-M's SRAM space. While the computation is
 *         made in integers, cast it to (void *). The gcc compiler gives
 *         a warning sign:
                cast to 'void *' from smaller integer type 'int'
 *         Simply ignore it.
 */
void *_ralloc(int size, int left, int right)
{
  printf("[_ralloc]: size=%d, left=%X, right=%X\n", size, left, right);

  // look for closest fit (smallest available block that is larger than size)
  // iterate over MCB
  int mid = (right + left) / 2;

  int addr = findBestBlock(size, left, right);
  if (!addr)
  {
    return NULL;
  }
  int block_size = getBlockSize(addr);
  //  base case: 2^u-1 < size <= 2^U, allocate the block
  int allocLevel = get_level(size);
  int blockLevel = get_level(block_size);

  printf("\t[_ralloc] mid = %X; address of chosen block: %X; size of chosen block: %d\n", mid, addr, block_size);
  printf("\tallocLevel: %d; blockLevel: %d\n", allocLevel, blockLevel);

  if (blockLevel > allocLevel)
  {
    int new_size = block_size / 2;
    // split and recurse
    *(short *)&array[m2a(addr)] = new_size;                                    // left buddy
    *(short *)&array[m2a(addr + new_size / min_size * mcb_ent_sz)] = new_size; // right buddy
    printf("[_ralloc] RECURSIVE CALL\n");
    // return _ralloc(size, left, right);
  }
  else
  {
  }
  // if no suitable memory can be found, return NULL
  return NULL;
}

/*
* TODO: _rfree
_rfree is _kfree's helper function that is recursively called to
 * deallocate a space, using the buddy memory allocaiton algorithm.
 * Implement it by yourself in step 1.
 *
 * @param  mcb_addr that corresponds to a SRAM space to deallocate
 * @return the same as the mcb_addr argument in success, otherwise 0.
 */
int _rfree(int mcb_addr)
{
  // printf( "_rfree: mcb[%x] = %x\n",
  //	  mcb_addr, *(short *)&array[ m2a( mcb_addr ) ] )

  return mcb_addr;
}

/*
  get the address of the MCB buddy
*/
int get_buddy(int block_index, int block_size)
{
  int entries_per_block = block_size / min_size; // maximum number of sub-blocks
  return block_index ^ entries_per_block;
}

// get the first level that is larger than size
// and is a power of 2
int get_level(int size)
{
  if (size <= min_size)
  {
    return 5;
  }

  int sizeCounter = min_size; // 32 bytes
  int level = 5;
  while (sizeCounter < size)
  {
    sizeCounter *= 2;
    level++;
  }

  return level;
}

// return the address of the best non-allocated
// block
// return -1 if no non-allocated block
// can be found
int findBestBlock(int size, int left, int right)
{
  // start from mcb_top
  printf("[findBestBlock]\n");
  for (int addr = left; addr <= right;)
  {
    short entry = *(short *)&array[m2a(addr)];
    if (entry == 0)
    {
      addr += 2;
      continue;
    }

    // mask to get first 16 bits
    int blockSize = getBlockSize(addr);
    // mask to get last 16 bits
    int allocated = getAllocated(addr);
    printf("[findBestBlock] mcb at %X: size = %d, %s\n", addr, blockSize, allocated ? "allocated" : "free");
    if (blockSize >= size && !allocated)
    {
      printf("\tthis block was chosen!\n");
      return addr;
    }
    addr += (blockSize / min_size) * mcb_ent_sz;
  }
  // no suitable block found
  return 0;
}

int getBlockSize(int addr)
{
  short data = *(short *)&array[m2a(addr)];
  return data & 0x7FFF;
}

void setBlockSize(int addr, int newSize)
{
}

int getAllocated(int addr)
{
  short data = *(short *)&array[m2a(addr)];
  return data & 0x8000;
}

/*
 * Initializes MCB entries. In step 2's assembly coding, this routine must
 * be called from Reset_Handler in startup_TM4C129.s before you invoke
 * driver.c's main( ).

 */
void _kinit()
{
  // Zeroing the heap space: no need to implement in step 2's assembly code.
  for (int i = 0x20001000; i < 0x20005000; i++)
    array[m2a(i)] = 0;

  // Initializing MCB: you need to implement in step 2's assembly code.
  // this means
  *(short *)&array[m2a(mcb_top)] = max_size;
  int maxLevel = get_level(max_size);
  printf("[_kinit] largest level: %d\n", maxLevel);
  printf("[_kinit] contents of array[m2a(mcb_top)]: 0x%X\n", *(short *)&array[m2a(mcb_top)]);

  for (int i = 0x20006804; i < 0x20006C00; i += 2)
  {
    array[m2a(i)] = 0;
    array[m2a(i + 1)] = 0;
  }
}

/*
 * Step 2 should call _kalloc from SVC_Handler.
 *
 * @param  the size of a requested memory space
 * @return a pointer to the allocated space

 */
void *_kalloc(int size)
{
  printf("_kalloc called\n");
  int level = get_level(size);
  printf("\tlevel = %d\n", level);
  return _ralloc(size, mcb_top, mcb_bot);
}

/*
 * Step 2 should call _kfree from SVC_Handler.
 *
 * @param  a pointer to the memory space to be deallocated.
 * @return the address of this deallocated space.
TODO: _kfree
 */
void *_kfree(void *ptr)
{
  int addr = (int)ptr;

  // validate the address
  // printf( "\n_kfree( %x )\n", ptr );
  if (addr < heap_top || addr > heap_bot)
    return NULL;

  // compute the mcb address corresponding to the addr to be deleted
  int mcb_addr = mcb_top + (addr - heap_top) / 16;

  if (_rfree(mcb_addr) == 0)
    return NULL;
  else
    return ptr;
}

// DO NOT COMPLETE
/*
 * _malloc should be implemented in stdlib.s in step 2.
 * _kalloc must be invoked through SVC in step 2.
 *
 * @param  the size of a requested memory space
 * @return a pointer to the allocated space
 */
void *_malloc(int size)
{
  static int init = 0;
  if (init == 0)
  {
    init = 1;
    _kinit(); // In step 2, you will call _kinit from Reset_Handler
  }
  // printArray();
  return _kalloc(size);
}

/*
 * _free should be implemented in stdlib.s in step 2.
 * _kfree must be invoked through SVC in step 2.
 *
 * @param  a pointer to the memory space to be deallocated.
 * @return the address of this deallocated space.
 */
void *_free(void *ptr)
{
  return _kfree(ptr);
}
