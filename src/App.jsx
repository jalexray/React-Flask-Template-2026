import { useState, useEffect } from 'react'
import { Button } from '@/components/ui/button'
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'

function App() {
  const [count, setCount] = useState(0)
  const [currentTime, setCurrentTime] = useState(null)

  useEffect(() => {
    fetch('/api/time')
      .then((res) => res.json())
      .then((data) => setCurrentTime(data.time))
      .catch(() => setCurrentTime(null))
  }, [])

  return (
    <main className="flex min-h-screen items-center justify-center bg-background p-8 text-foreground">
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle>React + Flask</CardTitle>
          <CardDescription>
            Vite, Tailwind CSS, and shadcn/ui on the front. Flask on the back.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-2 text-sm">
          <p>
            <span className="text-muted-foreground">Server time from </span>
            <code className="rounded bg-muted px-1 py-0.5">/api/time</code>
            <span className="text-muted-foreground">: </span>
            {currentTime === null
              ? 'unavailable (is Flask running?)'
              : new Date(currentTime * 1000).toLocaleString()}
          </p>
          <p className="text-muted-foreground">
            Edit <code className="rounded bg-muted px-1 py-0.5">src/App.jsx</code> and save to
            test HMR.
          </p>
        </CardContent>
        <CardFooter className="gap-2">
          <Button onClick={() => setCount((c) => c + 1)}>count is {count}</Button>
          <Button variant="outline" onClick={() => setCount(0)}>
            Reset
          </Button>
        </CardFooter>
      </Card>
    </main>
  )
}

export default App
