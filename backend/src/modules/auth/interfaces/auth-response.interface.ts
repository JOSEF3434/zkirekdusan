export interface AuthResponse {
  user: {
    id: string;
    email: string;
    username: string;
    role: string;
  };

  accessToken: string;

  refreshToken: string;
}
