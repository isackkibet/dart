import { getCurrentUser, logoutAction } from '@/lib/auth-actions'
import { redirect } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { LogOut, Camera, Users, Settings } from 'lucide-react'
import Link from 'next/link'

export default async function DashboardPage() {
  const user = await getCurrentUser()

  if (!user) {
    redirect('/auth/login')
  }

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <div className="border-b bg-card">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-foreground">Dashboard</h1>
              <p className="text-muted-foreground mt-1">
                Welcome back, {user.username}!
              </p>
            </div>
            <form action={logoutAction}>
              <Button variant="outline" size="sm" type="submit">
                <LogOut className="w-4 h-4 mr-2" />
                Log Out
              </Button>
            </form>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid md:grid-cols-3 gap-6 mb-12">
          {/* User Info Card */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Profile</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div>
                <p className="text-sm text-muted-foreground">Username</p>
                <p className="font-semibold text-foreground">{user.username}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Email</p>
                <p className="font-semibold text-foreground">{user.email}</p>
              </div>
              <Button variant="outline" size="sm" className="w-full mt-4">
                <Link href="/settings/profile">Edit Profile</Link>
              </Button>
            </CardContent>
          </Card>

          {/* Quick Actions */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Quick Actions</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              <Button variant="outline" size="sm"  className="w-full">
                <Link href="#sessions">
                  <Camera className="w-4 h-4 mr-2" />
                  New Session
                </Link>
              </Button>
              <Button variant="outline" size="sm"  className="w-full">
                <Link href="#organizations">
                  <Users className="w-4 h-4 mr-2" />
                  Manage Teams
                </Link>
              </Button>
            </CardContent>
          </Card>

          {/* Account Settings */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Settings</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              <Button variant="outline" size="sm"  className="w-full">
                <Link href="/settings/security">
                  <Settings className="w-4 h-4 mr-2" />
                  Security
                </Link>
              </Button>
              <Button variant="outline" size="sm"  className="w-full">
                <Link href="/settings/preferences">
                  <Settings className="w-4 h-4 mr-2" />
                  Preferences
                </Link>
              </Button>
            </CardContent>
          </Card>
        </div>

        {/* Getting Started */}
        <Card>
          <CardHeader>
            <CardTitle>Getting Started with YohPal Mesh</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid md:grid-cols-2 gap-6">
              <div>
                <h3 className="font-semibold text-foreground mb-2">1. Create a Mesh Session</h3>
                <p className="text-muted-foreground text-sm">
                  Set up your first multi-camera production session with your team members.
                </p>
              </div>
              <div>
                <h3 className="font-semibold text-foreground mb-2">2. Connect Your Devices</h3>
                <p className="text-muted-foreground text-sm">
                  Download the YohPal Mesh app on your iOS or Android devices and connect them.
                </p>
              </div>
              <div>
                <h3 className="font-semibold text-foreground mb-2">3. Choose Your Mode</h3>
                <p className="text-muted-foreground text-sm">
                  Select between AI Director Mode, Manual Switching, or Studio Mode for your needs.
                </p>
              </div>
              <div>
                <h3 className="font-semibold text-foreground mb-2">4. Start Recording</h3>
                <p className="text-muted-foreground text-sm">
                  Begin your production and let YohPal Mesh handle the professional video output.
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
