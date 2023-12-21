#include "mmu.h"
#include "pagesim.h"
#include "swapops.h"
#include "stats.h"

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"

/**
 * --------------------------------- PROBLEM 6 --------------------------------------
 * Checkout PDF section 7 for this problem
 * 
 * Page fault handler.
 * 
 * When the CPU encounters an invalid address mapping in a page table, it invokes the 
 * OS via this handler. Your job is to put a mapping in place so that the translation 
 * can succeed.
 * 
 * @param addr virtual address in the page that needs to be mapped into main memory.
 * 
 * HINTS:
 *      - You will need to use the global variable current_process when
 *      altering the frame table entry.
 *      - Use swap_exists() and swap_read() to update the data in the 
 *      frame as it is mapped in.
 * ----------------------------------------------------------------------------------
 */
void page_fault(vaddr_t addr) {
   // TODO: Get a new frame, then correctly update the page table and frame table
   stats.page_faults++;
   
   //Get the page table entry for the faulting virtual address
   vpn_t vpn = vaddr_vpn(addr);
   pte_t *pte = ((pte_t*) (mem + (PTBR * PAGE_SIZE))) + vpn;

   //Using free_frame() get the PFN of a new frame.
   pfn_t pfn = free_frame();

   //Update the flags
   pte -> pfn = pfn;
   pte -> valid = 1;
   pte -> dirty = 0;

   //Update the mapping
   frame_table[pfn].mapped = 1;
   frame_table[pfn].vpn = vpn;
   frame_table[pfn].process = current_process;
   
   paddr_t* newFrame = (paddr_t*) (mem + (PAGE_SIZE * pfn));
   if(swap_exists(pte)){ //Check to see if there is an existing swap entry for the faulting page table entry
      swap_read(pte, newFrame); //read in the saved frame into the new frame
   } else {
      memset(newFrame, 0, PAGE_SIZE); //clear the new frame.
   }
}

#pragma GCC diagnostic pop
