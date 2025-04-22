<style scoped lang="scss">
.quote-form {
  // ... existing code ...
  
  .total-row {
    border-top: 2px solid var(--cotalo-green);
    
    td {
      border-top: 2px solid var(--cotalo-green);
    }
  }
  
  .total-label {
    color: var(--cotalo-green);
  }
  
  input {
    &:focus {
      border-color: var(--cotalo-green);
    }
  }
}
</style> 