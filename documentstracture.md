# src/modules/auth/

│
├── constants
├── decorators
├── dto
├── guards
├── interfaces
├── strategies
├── types
│
├── auth.controller.ts
├── auth.module.ts
└── auth.service.ts

src/modules/auth

auth.controller.ts
auth.service.ts
auth.module.ts

dto/
    register.dto.ts
    login.dto.ts
    refresh-token.dto.ts
    forgot-password.dto.ts
    reset-password.dto.ts

guards/
    jwt-auth.guard.ts
    refresh-auth.guard.ts

strategies/
    jwt.strategy.ts
    refresh.strategy.ts

decorators/
    current-user.decorator.ts
    public.decorator.ts

interfaces/
    jwt-payload.interface.ts