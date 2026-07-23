'use client'

import { useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from '@/components/ui/card'
import { signupAction } from '@/lib/auth-actions'
import { Camera, Mail, Lock, User, Loader2, AlertCircle, CheckCircle, Eye, EyeOff } from 'lucide-react'
import { cn } from '@/lib/utils'

export default function SignupPage() {
  const router = useRouter()
  const [formData, setFormData] = useState({
    username: '',
    email: '',
    password: '',
    confirmPassword: '',
  })
  const [errors, setErrors] = useState<Record<string, string | undefined>>({})
  const [loading, setLoading] = useState(false)
  const [generalError, setGeneralError] = useState('')
  const [success, setSuccess] = useState(false)
  const [showPassword, setShowPassword] = useState(false)

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target
    setFormData((prev) => ({ ...prev, [name]: value }))
    if (errors[name]) {
      setErrors((prev) => {
        const newErrors = { ...prev }
        delete newErrors[name]
        return newErrors
      })
    }
  }

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    setLoading(true)
    setGeneralError('')
    setErrors({})

    try {
      const result = await signupAction(
        formData.email,
        formData.username,
        formData.password,
        formData.confirmPassword
      )

      if (!result.success) {
        if (result.errors) setErrors(result.errors)
        else if (result.error) setGeneralError(result.error)
      } else {
        setSuccess(true)
        setTimeout(() => router.push('/dashboard'), 1000)
      }
    } catch (error) {
      setGeneralError('An unexpected error occurred. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-muted/30 flex flex-col">
      <div className="p-6">
        <Link href="/" className="flex items-center space-x-2 w-fit">
          <div className="w-8 h-8 bg-primary rounded-md flex items-center justify-center">
            <Camera className="w-4 h-4 text-primary-foreground" />
          </div>
          <span className="font-semibold text-foreground tracking-tight">YohPal Mesh</span>
        </Link>
      </div>

      <div className="flex-1 flex items-center justify-center p-4">
        <Card className="w-full max-w-[400px] shadow-sm">
          <CardHeader className="space-y-1 pb-4">
            <CardTitle className="text-2xl font-semibold tracking-tight">Create an account</CardTitle>
            <CardDescription>Enter your details below to get started.</CardDescription>
          </CardHeader>

          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-4">
              {generalError && (
                <div className="p-3 bg-destructive/10 border border-destructive/20 rounded-md flex items-center gap-2 text-sm text-destructive">
                  <AlertCircle className="w-4 h-4" />
                  {generalError}
                </div>
              )}

              {success && (
                <div className="p-3 bg-emerald-500/10 border border-emerald-500/20 rounded-md flex items-center gap-2 text-sm text-emerald-600">
                  <CheckCircle className="w-4 h-4" />
                  Account created! Redirecting...
                </div>
              )}

              <div className="space-y-1.5">
                <Label htmlFor="username" className={errors.username ? 'text-destructive' : ''}>Username</Label>
                <div className="relative">
                  <User className="absolute left-3 top-2.5 w-4 h-4 text-muted-foreground" />
                  <Input
                    id="username" name="username" placeholder="johndoe"
                    value={formData.username} onChange={handleChange} disabled={loading}
                    className={cn("pl-9", errors.username && "border-destructive focus-visible:ring-destructive")}
                  />
                </div>
                {errors.username && <p className="text-[11px] text-destructive">{errors.username}</p>}
              </div>

              <div className="space-y-1.5">
                <Label htmlFor="email" className={errors.email ? 'text-destructive' : ''}>Email</Label>
                <div className="relative">
                  <Mail className="absolute left-3 top-2.5 w-4 h-4 text-muted-foreground" />
                  <Input
                    id="email" name="email" type="email" placeholder="m@example.com"
                    value={formData.email} onChange={handleChange} disabled={loading}
                    className={cn("pl-9", errors.email && "border-destructive focus-visible:ring-destructive")}
                  />
                </div>
                {errors.email && <p className="text-[11px] text-destructive">{errors.email}</p>}
              </div>

              <div className="space-y-1.5">
                <Label htmlFor="password" className={errors.password ? 'text-destructive' : ''}>Password</Label>
                <div className="relative">
                  <Lock className="absolute left-3 top-2.5 w-4 h-4 text-muted-foreground" />
                  <Input
                    id="password" name="password" type={showPassword ? 'text' : 'password'} placeholder="••••••••"
                    value={formData.password} onChange={handleChange} disabled={loading}
                    className={cn("pl-9 pr-9", errors.password && "border-destructive focus-visible:ring-destructive")}
                  />
                  <button
                    type="button" onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3 top-2.5 text-muted-foreground hover:text-foreground"
                  >
                    {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
                {errors.password && <p className="text-[11px] text-destructive">{errors.password}</p>}
              </div>

              <div className="space-y-1.5">
                <Label htmlFor="confirmPassword" className={errors.confirmPassword ? 'text-destructive' : ''}>Confirm Password</Label>
                <div className="relative">
                  <Lock className="absolute left-3 top-2.5 w-4 h-4 text-muted-foreground" />
                  <Input
                    id="confirmPassword" name="confirmPassword" type="password" placeholder="••••••••"
                    value={formData.confirmPassword} onChange={handleChange} disabled={loading}
                    className={cn("pl-9", errors.confirmPassword && "border-destructive focus-visible:ring-destructive")}
                  />
                </div>
                {errors.confirmPassword && <p className="text-[11px] text-destructive">{errors.confirmPassword}</p>}
              </div>

              <Button type="submit" disabled={loading || success} className="w-full">
                {loading && <Loader2 className="w-4 h-4 mr-2 animate-spin" />}
                {success ? 'Account Created' : 'Create Account'}
              </Button>
            </form>
          </CardContent>

          <CardFooter className="flex flex-col space-y-4 pt-0">
            <div className="relative w-full">
              <div className="absolute inset-0 flex items-center"><span className="w-full border-t" /></div>
              <div className="relative flex justify-center text-xs uppercase">
                <span className="bg-card px-2 text-muted-foreground">Or</span>
              </div>
            </div>
            <Button
              variant="outline"
              type="button"
              className="w-full"
              onClick={() => router.push('/auth/login')}
            >
              Log in to existing account
            </Button>
            <p className="text-center text-[11px] text-muted-foreground">
              By clicking continue, you agree to our{' '}
              <Link href="/terms" className="underline underline-offset-4 hover:text-primary">Terms</Link> and{' '}
              <Link href="/privacy" className="underline underline-offset-4 hover:text-primary">Privacy Policy</Link>.
            </p>
          </CardFooter>
        </Card>
      </div>
    </div>
  )
}